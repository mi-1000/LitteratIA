<script lang="ts">
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { APIReactionData, OnReactionFn, VoteData } from '$lib/chatService.svelte'
  import {
      arena,
      askChatBots,
      retryAskChatBots,
      updateReaction
  } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { ChatBot, VoteArea } from '.'

  let step = $state<'chat' | 'vote' >('chat')
  let prompt = $state('')
  let promptError = $state<string>()
  let reactionsByIndex = $state<Record<number, APIReactionData>>({})
  let voteData = $state<VoteData>({
    selected: undefined,
    a: {
      like: [],
      dislike: [],
      comment: ''
    },
    b: {
      like: [],
      dislike: [],
      comment: ''
    }
  })
  let showModelName = $derived(arena.showModelName)
  let invertModelLabels = $derived(arena.invertModelLabels)
  const chatbotDisabled = $derived(arena.chat.status !== 'complete' || step !== 'chat')

  const onReactionChange: OnReactionFn = async (reaction) => {
    // keep a map of reactions by message index and compute canVote from all reactions
    reactionsByIndex = { ...reactionsByIndex, [reaction.index]: reaction }
    await updateReaction(reaction)
  }

  function onRetry() {
    retryAskChatBots()
  }

  async function onPromptSubmit() {
    window.scrollTo(0, document.body.scrollHeight)
    const validationError = await askChatBots(prompt)
    if (validationError) {
      promptError = validationError
    } else {
      prompt = ''
    }
  }

  $effect(() => {
    // Sync local `step` with arena.chat.step so vote area appears when backend marks step=2
    if ((arena as any).chat?.step === 2 && step === 'chat') {
      step = 'vote'
    }
  })

  // Compute second header height for autoscrolling
  let footer = $state<HTMLElement>()
  let footerSize: number = $derived(step && footer ? footer.offsetHeight : 0)
  let innerWidth = $state(typeof window !== 'undefined' ? window.innerWidth : 1024)
  const inputMaxRows = $derived(innerWidth < 768 ? 2 : 5)

  function onResize() {
    footerSize = footer ? footer.offsetHeight : 0
    innerWidth = window.innerWidth
  }
</script>

<svelte:window onresize={onResize} />

<div style="--footer-size: {footerSize}px;" class="flex grow flex-col">
  <ChatBot disabled={chatbotDisabled} {onReactionChange} {onRetry} showModelName={showModelName} invertModelLabels={invertModelLabels} reactionsByIndex={reactionsByIndex} />

  {#if step === 'vote'}
    <VoteArea bind:value={voteData} disabled={false} showModelName={showModelName} invertModelLabels={invertModelLabels} />
  {/if}

  <div
      bind:this={footer}
      id="send-area"
      class="bg-very-light-grey bottom-0 gap-3 px-4 py-3 md:px-[20%] sticky z-2 mt-auto flex flex-col items-center"
    >
      {#if step === 'chat'}
        <div class="chat-input-wrapper">
          <TextPrompt
            id="chatbot-prompt"
            bind:value={prompt}
            label={m['chatbot.continuePrompt']()}
            placeholder={m['chatbot.continuePrompt']()}
            error={promptError}
            hideLabel
            rows={1}
            maxRows={inputMaxRows}
            onSubmit={onPromptSubmit}
            class="mb-0! w-full"
          />

          <button
            id="send-btn"
            disabled={arena.chat.status !== 'complete' || prompt === ''}
            class="send-inside-btn btn-color hidden md:flex"
            onclick={onPromptSubmit}
            title={m['words.send']()}
          >
            <i class="i-bi-arrow-up block text-lg"></i>
          </button>

          <button
            id="send-btn-mobile"
            aria-label={m['words.send']()}
            disabled={arena.chat.status !== 'complete' || prompt === ''}
            class="send-inside-btn btn-color flex md:hidden"
            onclick={onPromptSubmit}
            title={m['words.send']()}
          >
            <i class="i-bi-arrow-up block text-lg"></i>
          </button>
        </div>
      {/if}
    </div>
</div>

<style>
  .chat-input-wrapper {
    position: relative;
    display: flex;
    width: 100%;
    align-items: center;
  }

  /* Leave space for the floating button (works on mobile & desktop) */
  .chat-input-wrapper :global(textarea) {
    padding-right: 3.25rem !important;
  }

  .send-inside-btn {
    display: flex;
    position: absolute;
    right: 0.5rem;
    top: 50%;
    transform: translateY(-50%);
    width: 2.25rem;
    height: 2.25rem;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    border: none;
    cursor: pointer;
    transition: background 0.2s, opacity 0.2s;
    z-index: 2;
    padding: 0;
    min-width: 0;
  }

  .send-inside-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
</style>
