"""
LiteLLM integration for unified API communication.

This module provides a unified interface to call different LLM APIs (OpenAI, Google Vertex AI,
OpenRouter, etc.) through LiteLLM, handling streaming responses, token counting, and error handling.
"""

import json
import logging
from typing import TYPE_CHECKING, Generator, TypedDict, Union, cast

import litellm

from backend.config import GLOBAL_TIMEOUT, settings
from backend.errors import ContextTooLongError, EmptyResponseError

if TYPE_CHECKING:
    from fastapi import Request

    from backend.arena.models import AnyMessage
    from backend.llms.models import Endpoint

logger = logging.getLogger("litteratia")

# Load Google Cloud credentials for Vertex AI if available
vertex_credentials_json: str | None = None
if settings.GOOGLE_APPLICATION_CREDENTIALS:
    with open(settings.GOOGLE_APPLICATION_CREDENTIALS, "r") as file:
        vertex_credentials = json.load(file)
        vertex_credentials_json = json.dumps(vertex_credentials)
else:
    logger.warning("No Google creds detected!")
    vertex_credentials_json = None


def get_api_key(endpoint: "Endpoint") -> str | None:
    """
    Get the appropriate API key for an endpoint.

    Different providers require different API keys:
    - Albert (French LLM): ALBERT_KEY
    - HuggingFace Inference: HF_INFERENCE_KEY
    - OpenRouter/Vertex: handled by LiteLLM from env variables

    Args:
        endpoint: Endpoint configuration dict with api_base

    Returns:
        str: API key, or None if using standard provider (OpenRouter/Vertex)
    """
    # Albert is French government LLM
    # "api_base": "https://albert.api.etalab.gouv.fr/v1/",

    # "api_type": "huggingface/cohere" doesn't work, using the openai api type and api_base="https://router.huggingface.co/cohere/compatibility/v1/"
    if endpoint.api_base and "albert.api.etalab.gouv.fr" in endpoint.api_base:
        return settings.ALBERT_KEY
    # HuggingFace Inference API
    if endpoint.api_base and "huggingface.co" in endpoint.api_base:
        return settings.HF_INFERENCE_KEY
    # Ordbogen.ai (Danish LLM)
    if endpoint.api_base and "ordbogen.ai" in endpoint.api_base:
        return settings.ORDBOGEN_API_KEY
    # OpenRouter and Vertex AI are handled by LiteLLM reading env variables directly
    # OPENROUTER_API_KEY and Google credentials are checked automatically
    # Normally no need for OpenRouter, litellm reads OPENROUTER_API_KEY env value
    # And no need for Vertex, handled with GOOGLE_APPLICATION_CREDENTIALS pointing to a json file
    return None


class LLMResponse(TypedDict):
    generation_id: str
    reasoning: str
    content: str
    output_tokens: int | None


def litellm_stream_iter(
    model_name: str,
    endpoint: "Endpoint",
    messages: list["AnyMessage"],
    temperature: float,
    max_new_tokens: int,
    top_p: float | None = None,
    top_k: int | None = None,
    stream_timeout_seconds: float | None = None,
    retry_timeout_seconds: float | None = None,
    request: Union["Request", None] = None,
    include_reasoning: bool = False,  # FIXME Legacy ?
    enable_reasoning: bool = False,  # FIXME Legacy ?
) -> Generator[LLMResponse]:
    """
    Stream responses from an LLM API using LiteLLM.

    This function handles unified API calls to various LLM providers through LiteLLM,
    manages streaming responses, and processes tokens and metadata.

    Args:
        model_name: Model id
        endpoint: Model Endpoint data
        messages: List of messages to be serialized for llm call
        temperature: Sampling temperature for response diversity
        max_new_tokens: Maximum tokens to generate
        top_p: Nucleus sampling parameter
        top_k: Top-k sampling parameter
        stream_timeout_seconds: Streaming timeout for upstream provider call
        retry_timeout_seconds: Timeout for one-shot non-streaming fallback retry
        request: FastAPI request for logging
        include_reasoning: Whether to include reasoning in response
        enable_reasoning: Whether to enable reasoning mode

    Yields:
        Dict containing: content, reasoning, output_tokens, generation_id
    """

    # Determine base_url and LiteLLM model identifier.
    # If endpoint is not provided, fall back to global OLLAMA_API_BASE and assume Ollama provider.
    if endpoint is None:
        base_url = settings.OLLAMA_API_BASE
        litellm_model_name = f"ollama/{model_name}"
        api_key = None
        endpoint_dump = None
    else:
        base_url = endpoint.api_base or settings.OLLAMA_API_BASE
        litellm_model_name = f"{endpoint.api_type}/{endpoint.api_model_id}"
        api_key = get_api_key(endpoint)
        try:
            endpoint_dump = endpoint.model_dump(mode="json")
        except Exception:
            endpoint_dump = None

    logger.info(
        f"using endpoint {litellm_model_name} for {model_name}: {endpoint_dump}",
        extra={"request": request},
    )

    # Debug mode can be enabled but is very verbose for streaming
    # from backend.config import debug
    # if debug:
    #     litellm._turn_on_debug()

    # Configure Sentry error tracking if available
    if settings.SENTRY_DSN:
        litellm.input_callback = ["sentry"]  # adds sentry breadcrumbing
        litellm.failure_callback.append("sentry")

    # Set Vertex AI location for Google Cloud models (fallback to settings)
    litellm.vertex_location = (
        endpoint.vertex_ai_location
        if endpoint and getattr(endpoint, "vertex_ai_location", None)
        else None
    ) or settings.VERTEXAI_LOCATION

    # nice to have: openrouter specific params
    # completion = client.chat.completions.create(
    #   extra_headers={
    #     "HTTP-Referer": "<YOUR_SITE_URL>", # Optional. Site URL for rankings on openrouter.ai.
    #     "X-Title": "<YOUR_SITE_NAME>", # Optional. Site title for rankings on openrouter.ai.
    #   },

    # Build parameters for LiteLLM API call
    # Prepare messages to send to LiteLLM: exclude a trailing empty assistant message
    # since some provider prompt transformers expect the last message to be a user/assistant pair
    messages_to_send = list(messages)
    if messages_to_send:
        last = messages_to_send[-1]
        if getattr(last, "role", None) == "assistant" and (
            not getattr(last, "content", None) or not str(last.content).strip()
        ):
            messages_to_send = messages_to_send[:-1]

    # Serialize messages for LiteLLM (only role and content)
    serialized_messages = [
        msg.model_dump(include={"role", "content"}) for msg in messages_to_send
    ]

    logger.debug("Serialized messages for LLM: %s", serialized_messages)

    if stream_timeout_seconds is None:
        stream_timeout_seconds = settings.LLM_STREAM_TIMEOUT_SECONDS
    if retry_timeout_seconds is None:
        retry_timeout_seconds = settings.LLM_RETRY_TIMEOUT_SECONDS

    kwargs = {
        "timeout": GLOBAL_TIMEOUT,
        "stream_timeout": stream_timeout_seconds,
        "api_version": (endpoint.api_version if endpoint is not None else None),
        "base_url": base_url,
        "api_key": api_key,
        # max_retries can be added if needed
        "model": litellm_model_name,
        # Only pass supported message args 'role' and 'content'
        "messages": serialized_messages,
        "temperature": temperature,
        "max_tokens": max_new_tokens,
        "stream": True,  # Enable streaming for real-time responses
        "vertex_credentials": vertex_credentials_json,
        "vertex_ai_location": litellm.vertex_location,
    }

    if top_p is not None:
        kwargs["top_p"] = top_p
    if top_k is not None:
        kwargs["top_k"] = top_k

    # Use mock response for testing if enabled
    if settings.MOCK_RESPONSE:
        logger.warning(f"MOCK_RESPONSE enabled")
        kwargs["mock_response"] = (
            """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam feugiat arcu non nunc interdum mattis. Pellentesque fermentum ullamcorper lectus ut finibus. Nunc id sem nec nisi vulputate viverra. Curabitur massa sapien, elementum vel scelerisque eget, iaculis eget justo. Etiam suscipit est purus, in sollicitudin sem ultricies at. Maecenas maximus purus massa, ut imperdiet nisl feugiat in. Ut mollis eleifend venenatis.
"""
# In quis elit facilisis, iaculis nunc et, scelerisque tortor. Maecenas non enim eu nulla eleifend efficitur. Suspendisse vel ante ut leo vehicula sodales at ac massa. Sed vitae urna justo. Vestibulum vestibulum ex sit amet erat ornare, non tristique odio dapibus. Vivamus porta felis a urna dictum volutpat. Ut porttitor augue consectetur erat feugiat, a ornare urna facilisis. In consequat aliquam dolor scelerisque imperdiet. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Aliquam accumsan ante id nunc semper, non tempus tellus vulputate. Aenean iaculis lacinia eros, in semper nisl laoreet vel. Suspendisse eu nunc vel nulla malesuada efficitur. Nunc porta, quam sit amet consectetur hendrerit, nibh odio pretium justo, in rhoncus mi sem et tortor. Nullam ultricies malesuada purus nec finibus. Morbi suscipit gravida nibh ac sagittis. Curabitur fringilla, massa vitae rutrum convallis, mi augue mollis urna, eu facilisis risus ipsum non augue.

# Fusce vestibulum viverra mauris, aliquam facilisis ante. Morbi vestibulum ipsum eget felis ornare tempus. Duis in tellus leo. Pellentesque quam quam, mattis vel interdum non, egestas at risus. Maecenas luctus, risus porta vulputate scelerisque, elit quam vehicula libero, et dictum arcu metus a urna. Mauris auctor mattis orci, id laoreet lacus commodo eget. Sed tortor ligula, blandit a nisl non, aliquam tincidunt nisi. Aenean hendrerit erat sed ligula varius malesuada. Sed id magna lacus. Integer aliquam est ligula, ac egestas orci iaculis eu. Sed facilisis turpis arcu, ultricies molestie ante condimentum vel. Cras porttitor fringilla volutpat.

# In porta dolor ligula, vitae tincidunt mi accumsan a. Sed non risus dictum, porta ante id, consectetur urna. Morbi ac est a nunc pretium cursus eu et lectus. Donec purus ante, euismod nec eros quis, porta luctus erat. Ut sit amet porta libero. In sem ipsum, rutrum at rutrum ut, porttitor eget sapien. Cras quis ipsum augue. Cras eget condimentum nibh, vel aliquam nisl. Vestibulum semper, erat quis feugiat laoreet, ipsum ante aliquam mauris, at euismod augue sapien sit amet neque. Quisque pretium fringilla porttitor. In magna mi, viverra ac tortor et, vulputate lacinia nunc. Ut arcu tortor, sodales sit amet quam sed, euismod pharetra quam. Pellentesque eu nisl nunc.

# Etiam sed semper mauris, et gravida diam. Ut suscipit quis elit vel condimentum. Aliquam dapibus, odio sed auctor auctor, nulla erat sollicitudin leo, id consectetur massa augue in purus. Sed commodo dictum enim eget maximus. Mauris eu nibh eros. Aliquam lobortis fringilla lorem, dignissim fermentum quam mollis pharetra. Nulla vel convallis mi, id semper nunc.
            # """
        )

    # Request token usage reporting (except for Aya which doesn't support it)
    if "c4ai-aya-expanse-32b" not in litellm_model_name:
        kwargs["stream_options"] = {"include_usage": True}

    # Enable extended reasoning (e.g., o1 models)
    if include_reasoning:
        kwargs["include_reasoning"] = True

    # Some models support enable_reasoning mode
    if enable_reasoning:
        kwargs["enable_reasoning"] = True

    # Make the API call through LiteLLM
    try:
        response: Generator[litellm.ModelResponse] = litellm.completion(**kwargs)
    except litellm.ContextWindowExceededError as e:
        logger.error(
            f"context_window_exceeded: {litellm_model_name}: {e}",
            extra={"request": request},
        )
        raise ContextTooLongError from e

    # OpenRouter specific params could be added here
    # transforms = [""], route= ""

    # Data dict to accumulate response metadata
    data: LLMResponse = {
        "generation_id": "",
        "reasoning": "",
        "content": "",
        "output_tokens": None,
    }

    # Process streaming chunks from the API
    try:
        for chunk in response:
            # Extract generation ID for tracking/debugging
            if not data["generation_id"] and chunk.id:
                data["generation_id"] = chunk.id
                logger.debug(
                    f"Response stream started for '{litellm_model_name}' with generation_id='{chunk.id}'",
                    extra={"request": request},
                )
            # Extract token count from streaming completion (if available)
            if hasattr(chunk, "usage") and hasattr(chunk.usage, "completion_tokens"):
                data["output_tokens"] = chunk.usage.completion_tokens
                logger.debug(
                    f"reported output tokens for api {endpoint.api_base} and model {litellm_model_name}: {data['output_tokens']}",
                    extra={"request": request},
                )
            # Process content chunks
            if len(chunk.choices) > 0:
                choice = cast(litellm.types.utils.StreamingChoices, chunk.choices[0])

                # Accumulate text and reasoning across chunks
                if delta := choice.get("delta"):
                    # Get the text content of this chunk
                    if content := choice.delta.get("content"):
                        data["content"] += content
                    # Get reasoning content (for reasoning models)
                    if reasoning := delta.get("reasoning_content") or delta.get(
                        "reasoning" or delta.get("thinking")
                    ):
                        data["reasoning"] += reasoning

                # Check for generation completion signal
                if choice.finish_reason == "stop":
                    break
                elif choice.finish_reason == "length":
                    # Output truncated at max_tokens limit — response is still valid
                    logger.warning(
                        "output_truncated_at_max_tokens: " + str(chunk),
                        extra={"request": request},
                    )
                    break

                # Yield partial results for streaming to frontend
                yield data

    except Exception as e:
        # Catch upstream API/connection errors coming from LiteLLM (e.g. unparsable
        # Ollama chunks or timeouts). Try a single non-streaming retry for cases
        # where the provider emits unparsable streaming chunks (some Ollama models
        # send empty interim chunks). If retry fails or returns empty, raise
        # EmptyResponseError so higher layers can handle it explicitly.
        logger.warning(
            f"litellm stream error for {litellm_model_name}: {e}",
            exc_info=False,
            extra={"request": request},
        )

        # If the error looks like an Ollama unparsable-chunk, attempt one non-streaming retry
        try:
            from litellm import exceptions as _lit_ex

            is_ollama_parse_err = isinstance(
                e, _lit_ex.APIConnectionError
            ) and "Unable to parse ollama chunk" in str(e)
        except Exception:
            is_ollama_parse_err = False

        if is_ollama_parse_err:
            logger.info(
                f"Attempting non-streaming retry for {litellm_model_name} after unparsable ollama chunk",
                extra={"request": request},
            )
            # Prepare retry kwargs: copy and switch off streaming
            retry_kwargs = dict(kwargs)
            retry_kwargs["stream"] = False
            retry_kwargs["timeout"] = retry_timeout_seconds
            try:
                final_resp = litellm.completion(**retry_kwargs)
                # Try to extract text from common response shapes
                final_text = ""
                final_gen_id = ""
                if hasattr(final_resp, "choices") and len(final_resp.choices) > 0:
                    ch = final_resp.choices[0]
                    # litellm choice may expose .message, .text or dict-like
                    if hasattr(ch, "message") and ch.message:
                        final_text = (
                            ch.message.get("content", "")
                            if isinstance(ch.message, dict)
                            else getattr(ch.message, "content", "")
                        )
                    elif hasattr(ch, "text"):
                        final_text = getattr(ch, "text") or ""
                    elif isinstance(ch, dict):
                        final_text = (
                            ch.get("text")
                            or (
                                ch.get("message")
                                and (
                                    ch.get("message").get("content")
                                    if isinstance(ch.get("message"), dict)
                                    else ""
                                )
                            )
                            or ""
                        )
                if hasattr(final_resp, "id") and final_resp.id:
                    final_gen_id = final_resp.id

                if final_text and final_text.strip():
                    data["content"] = final_text
                    if final_gen_id:
                        data["generation_id"] = final_gen_id
                    yield data
                    return
                else:
                    logger.warning(
                        f"Non-streaming retry returned empty for {litellm_model_name}",
                        extra={"request": request},
                    )
                    raise EmptyResponseError(response=e)
            except Exception as retry_e:
                logger.error(
                    f"Non-streaming retry failed for {litellm_model_name}: {retry_e}",
                    exc_info=True,
                    extra={"request": request},
                )
                raise EmptyResponseError(response=retry_e) from retry_e
        else:
            # For other errors, log full exception and raise EmptyResponseError
            logger.error(
                f"litellm stream fatal error for {litellm_model_name}: {e}",
                exc_info=True,
                extra={"request": request},
            )
            raise EmptyResponseError(response=e)
    else:
        logger.debug(
            f"Response stream ended for '{litellm_model_name}' with generation_id='{chunk.id}'",
            extra={"request": request},
        )

    # Final yield after loop completes
    yield data
