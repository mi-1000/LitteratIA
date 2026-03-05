<script lang="ts">
  import { Button } from '$components/dsfr'
  import Footer from '$components/Footer.svelte'
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { OnReactionFn, RevealData, VoteData } from '$lib/chatService.svelte'
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

  const chatbotDisabled = $derived(arena.chat.status !== 'complete' || step !== 'chat')
  const revealDisabled = $derived(
    arena.chat.status !== 'complete' || (step === 'vote' && voteData.selected === undefined)
  )

  const onReactionChange: OnReactionFn = async (reaction) => {
    canVote = reaction.liked === null
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
  <ChatBot disabled={chatbotDisabled} {onReactionChange} {onRetry} {onVote} />

  {#if step === 'vote' || (step === 'reveal' && canVote)}
    <VoteArea bind:value={voteData} disabled={step === 'reveal'} />
  {/if}

  {#if step === 'reveal' && revealData}
    <RevealArea data={revealData} />
    <Footer />
  {:else}
    <div
      bind:this={footer}
      id="send-area"
      class="bg-very-light-grey bottom-0 gap-3 px-4 py-3 md:px-[20%] sticky z-2 mt-auto flex flex-col items-center"
    >
      {#if step === 'chat'}
        <div class="relative flex w-full items-end">
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
            class="mb-0! w-full md:pr-14!"
          />

          <button
            id="send-btn"
            disabled={arena.chat.status !== 'complete' || prompt === ''}
            class="send-inside-btn btn-color"
            onclick={onPromptSubmit}
            title={m['words.send']()}
          >
            <i class="i-bi-arrow-up block text-lg"></i>
          </button>
        </div>

        <Button
          id="send-btn-mobile"
          text={m['words.send']()}
          disabled={arena.chat.status !== 'complete' || prompt === ''}
          class="md:hidden! w-full! btn-color"
          onclick={onPromptSubmit}
        />
      {/if}

      <Button
        text={m['chatbot.revealButton']()}
        disabled={revealDisabled}
        class="md:w-fit! w-full!"
        onclick={onRevealModels}
      />
    </div>
  {/if}
</div>

<style>
  .send-inside-btn {
    display: none;
  }

  @media (min-width: 48em) {
    .send-inside-btn {
      display: flex;
      position: absolute;
      right: 0.75rem;
      bottom: 0.75rem;
      width: 2.25rem;
      height: 2.25rem;
      align-items: center;
      justify-content: center;
      border-radius: 0.5rem;
      border: none;
      background: var(--text-action-high-blue-france);
      color: white;
      cursor: pointer;
      transition: background 0.2s, opacity 0.2s;
      z-index: 2;
    }

    .send-inside-btn:hover {
      background: var(--cg-blue-france-main-525-hover);
    }

    .send-inside-btn:disabled {
      opacity: 0.4;
      cursor: not-allowed;
    }
  }
</style>
