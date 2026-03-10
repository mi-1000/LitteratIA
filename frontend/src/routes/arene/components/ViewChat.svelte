<script lang="ts">
  import { Button } from '$components/dsfr'
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { APIReactionData, OnReactionFn, RevealData, VoteData } from '$lib/chatService.svelte'
  import {
      arena,
      askChatBots,
      getReveal,
      postVoteGetReveal,
      retryAskChatBots,
      updateReaction
  } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { ChatBot, RevealArea, VoteArea } from '.'

  let step = $state<'chat' | 'vote' | 'reveal'>('chat')
  let prompt = $state('')
  let promptError = $state<string>()
  let canVote = $state<boolean | null>(true)
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
  let revealData = $state<RevealData>()
  let showModelName = $derived(arena.showModelName)
  const chatbotDisabled = $derived(arena.chat.status !== 'complete' || step !== 'chat')
  const revealDisabled = $derived(
    arena.chat.status !== 'complete' || (step === 'vote' && voteData.selected === undefined)
  )

  const onReactionChange: OnReactionFn = async (reaction) => {
    // keep a map of reactions by message index and compute canVote from all reactions
    reactionsByIndex = { ...reactionsByIndex, [reaction.index]: reaction }
    const reactions = Object.values(reactionsByIndex)
    canVote = reactions.length === 0 ? true : !reactions.some((r) => r.liked !== null) // TODO update backend to enforce voting even if there are already reactions (and leave canVote always true)
    await updateReaction(reaction)
  }

  function onRetry() {
    retryAskChatBots()
  }

  function onVote() {
    // FIXME if user already react? go to reveal for now
    onRevealModels()
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

  async function onRevealModels() {
    // if chat as reactions, no need to show vote
    if (canVote === false) {
      revealData = await getReveal()
      step = 'reveal'
      arena.chat.step = 2
    } else if (step === 'vote') {
      if (!voteData.selected) return
      revealData = await postVoteGetReveal(voteData as Required<VoteData>)
      step = 'reveal'
      arena.chat.step = 2
    } else {
      step = 'vote'
    }
  }

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
  <ChatBot disabled={chatbotDisabled} {onReactionChange} {onRetry} {onVote} showModelName={showModelName} />

  {#if step === 'vote' || (step === 'reveal' && canVote)}
    <VoteArea bind:value={voteData} disabled={step === 'reveal'} />
  {/if}

  {#if step === 'reveal' && revealData}
    <RevealArea data={revealData} />
  {:else}
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
      <Button
        text={showModelName ? m['chatbot.revealButton']() : m['chatbot.voteButton']()}
        disabled={revealDisabled}
        class="md:w-fit! w-full! btn-color"
        onclick={onRevealModels}
      />
    </div>
  {/if}
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
