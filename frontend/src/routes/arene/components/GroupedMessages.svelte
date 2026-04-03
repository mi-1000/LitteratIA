<script lang="ts">
  import type { ChatRound, OnReactionFn } from '$lib/chatService.svelte'
  import { arena } from '$lib/chatService.svelte'
  import { scrollTo } from '$lib/helpers/attachments'
  import { m } from '$lib/i18n/messages'
  import { MessageBot, MessageUser, ReactPanel } from '.'

  let {
    round,
    disabled,
    onReactionChange,
    showModelName = false,
    invertModelLabels = false,
    reactionsByIndex = {} as Record<number, any>
  }: {
    round: ChatRound
    disabled: boolean
    onReactionChange: OnReactionFn
    showModelName?: boolean | 'showA' | 'showB'
    invertModelLabels?: boolean
    reactionsByIndex?: Record<number, any>
  } = $props()

  let userMessageSize = $state(0)
  let anyBlocking = $derived(
    arena.chat.a.status === 'generating' ||
      arena.chat.b.status === 'generating' ||
      arena.chat.status !== 'complete'
  )

  // compute whether this round is older than the latest user round
  const prevLocked = $derived.by(() => {
    const { a } = arena.chat
    const base = a.messages.length ? 'a' : 'b'
    const userMessages = arena.chat[base].messages.filter((m) => m.role === 'user')
    const lastIndex = userMessages.length ? userMessages.length - 1 : 0
    return round.index < lastIndex
  })
</script>

<div
  class="grouped-messages not-last:mb-15 px-4 md:px-8 xl:px-16"
  style="--message-size: {userMessageSize}px;"
  {@attach scrollTo}
>
  <MessageUser bind:size={userMessageSize} message={round.user} />

  <div class="grid grid-cols-1 md:grid-cols-2 gap-10 md:gap-6 w-full max-w-full overflow-hidden">
    {#if round.a && round.b && round.showMessages}
        <div class="min-w-0">
          <MessageBot
            message={round.a}
            index={round.index}
            {disabled}
            {onReactionChange}
            {showModelName}
            {invertModelLabels}
            side="A"
          />
        </div>
        <div class="min-w-0">
          <MessageBot
            message={round.b}
            index={round.index}
            {disabled}
            {onReactionChange}
            {showModelName}
            {invertModelLabels}
            side="B"
          />
        </div>
    {/if}
  </div>

  {#if round.a && round.b}
    {#if round.a && round.b}
      <div
        class={[
          'cg-border rounded-lg mt-4 bg-white p-4 md:p-6',
          anyBlocking || prevLocked ? 'cursor-not-allowed opacity-50' : ''
        ]}
        title={anyBlocking ? m['vote.wait']() : prevLocked ? m['vote.locked']() : ''}
        aria-disabled={anyBlocking || prevLocked}
      >
        <div class="mb-3 font-bold text-center">{m['vote.title']()}</div>
        <div class="gap-4 md:grid-cols-2 grid">
          <div class="col-span-2">
            <ReactPanel disabled={anyBlocking || prevLocked || disabled} index={round.index * 2 + 1} />
          </div>
        </div>
      </div>
    {/if}
  {/if}
</div>
