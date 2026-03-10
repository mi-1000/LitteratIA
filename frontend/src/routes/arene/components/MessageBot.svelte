<script lang="ts">
  import Copy from '$components/Copy.svelte'
  import { Icon } from '$components/dsfr'
  import Markdown from '$components/markdown/MarkdownCode.svelte'
  import Pending from '$components/Pending.svelte'
  import type { APIReactionData, AssistantMessage, OnReactionFn } from '$lib/chatService.svelte'
  import { arena } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { getModelsContext } from '$lib/models'
  import { sanitize } from '$lib/utils/commons'
  import { LikeDislike, LikePanel } from '.'

  export type MessageBotProps = {
    message: AssistantMessage
    index: number
    disabled?: boolean
    onReactionChange: OnReactionFn
  }

  export type MessageBotExtra = {
    showModelName?: boolean | 'showA' | 'showB'
    side?: 'A' | 'B'
  }

  let { message, index, disabled = false, onReactionChange, showModelName = false, side = 'A' }: MessageBotProps & MessageBotExtra = $props()

  function shouldShowFor(sideLocal: string) {
    const val = showModelName as any
    if (val === true) return true
    if (val === 'showA' && sideLocal.toLowerCase() === 'a') return true
    if (val === 'showB' && sideLocal.toLowerCase() === 'b') return true
    return false
  }

  const bot = message.metadata.bot
  function prettifyBotId(id: string) {
    return id.replace(/[-_]+/g, ' ').replace(/(?:^|\s)\S/g, (s) => s.toUpperCase())
  }

  // Always return an object { provider, model }.
  // If provider is unknown, provider === '' and model contains a readable label.
  function splitModelId(id: string) {
    const s = String(id || '')
    const parts = s.split('/')
    if (parts.length >= 2) {
      const provider = parts[0]
      const model = parts.slice(1).join('/')
      return { provider, model }
    }
    return { provider: '', model: s }
  }

  function getModelParts(): { provider: string; model: string } {
    // If anonymized for this side, return empty provider and anonymized label as model
    if (!shouldShowFor(side)) return { provider: '', model: m['chatbot.modelAnon']({ side }) }

    // Prefer backend-provided mapping if available
    try {
      const map = (arena as any).chat?.model_map
      const sideKey = side.toLowerCase()
      if (map && map[sideKey]) {
        const modelId = map[sideKey]
        try {
          const ctx = getModelsContext()
          if (ctx && ctx.models) {
            const found = ctx.models.find((mm: any) => mm.id === modelId || mm.simple_name === modelId)
            if (found) {
              // Prefer organisation/simple_name if present in models context
              const provider = found.organisation ? String(found.organisation) : ''
              const model = String(found.simple_name || modelId)
              return { provider, model }
            }
          }
        } catch (e) {
          // ignore and fallback
        }
        return splitModelId(prettifyBotId(modelId))
      }
    } catch (e) {
      // ignore
    }

    // Try i18n mapping for specific bots
    try {
      const fn = (m as any)[`models.names.${bot}`](side || 'A')
      if (typeof fn === 'function') {
        const v = fn()
        if (v && v.toString().trim() !== '') return splitModelId(String(v))
      }
    } catch (e) {
      // ignore
    }

    // Fallback to prettified bot id
    return splitModelId(prettifyBotId(bot))
  }

  // Return HTML string with provider in italic and model in bold.
  function getModelHtml(): string {
    const parts = getModelParts()
    // sanitize parts separately to avoid accidental tags in provider/model
    const prov = parts.provider ? `<span class="provider-name">${escapeHtml(parts.provider)}/</span>` : ''
    const model = escapeHtml(parts.model)
    if (prov) return `${prov}${model}`
    return model
  }

  function escapeHtml(input: string) {
    return String(input)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }
  const reaction = $state<APIReactionData>({
    index: index * 2 + 1,
    bot: message.metadata.bot,
    liked: null,
    prefs: [],
    comment: '',
    value: message.content
  })

  function onLikedChanged() {
    reaction.prefs = []
    // FIXME reset comment?
    dispatchOnReactionChange()
  }

  function dispatchOnReactionChange() {
    onReactionChange({
      ...reaction,
      value: message.content
    })
  }
</script>

<div class="flex flex-col">
  <div
    class="message-bot cg-border rounded-lg! bg-white relative flex h-full flex-col overflow-hidden"
  >
    <div class="overflow-y-auto flex-1 px-5">
      <div class="top-0 bg-white pb-5 pt-7 sticky z-2 flex items-center">
        <div class="c-bot-disk-{bot}"></div>
        <h3 class="ms-2! mb-0! text-base!">
          {#if !shouldShowFor(side)}
            {m['chatbot.modelAnon']({ side })}
          {:else}
            {@html getModelHtml()}
          {/if}
        </h3>
      </div>

      {#if message.reasoning.trim() !== ''}
        <section class="fr-accordion mb-8 py-2">
          <div class="fr-highlight ms-0! ps-0!">
            <h3 class="fr-accordion__title ms-1!">
              <button
                type="button"
                class="fr-accordion__btn text-primary! bg-transparent!"
                aria-expanded="true"
                aria-controls="reasoning-{message.metadata.generation_id}"
              >
                <Icon icon="i-ri-brain-2-line" class="text-primary me-1" />
                {#if message.content === '' && message.generating}
                  {m['chatbot.reasoning.inProgress']()}
                {:else}
                  {m['chatbot.reasoning.finished']()}
                {/if}
              </button>
            </h3>
            <div
              id="reasoning-{message.metadata.generation_id}"
              class="fr-collapse m-0! p-0! text-sm text-[#8B8B8B]"
            >
              <div class="px-5 py-4">
                {@html sanitize(message.reasoning.split('\n').join('<br>'))}
              </div>
            </div>
          </div>
        </section>
      {/if}

      <Markdown message={message.content} chatbot />

      {#if message.generating}
        <Pending message={m['chatbot.loading']()} />
      {/if}
    </div>

    <div class="icon-bar bg-white px-5 py-3 flex shrink-0 sticky bottom-0 z-2">
      <Copy value={message.content} />

      <div class="gap-2 ms-auto flex">
        <LikeDislike
          bind:liked={reaction.liked}
          disabled={message.generating || disabled}
          onChange={onLikedChanged}
        />
      </div>
    </div>
  </div>

  {#if reaction.liked !== null}
    <div class="cg-border rounded-lg! mt-3 bg-white p-5 border-dashed!">
      <LikePanel
        id={message.metadata.generation_id}
        kind={reaction.liked ? 'like' : 'dislike'}
        show={true}
        bind:selection={reaction.prefs}
        bind:comment={reaction.comment}
        onSelectionChange={dispatchOnReactionChange}
        onCommentChange={dispatchOnReactionChange}
        model={bot.toUpperCase()}
      />
    </div>
  {/if}
</div>

<style>
  .message-bot {
    --extra-margin: 2.5rem;
    --five-lines: 5rem;
    max-height: calc(
      100vh - var(--second-header-size) - var(--footer-size) - var(--message-size) -
        var(--extra-margin) - var(--five-lines)
    );
    min-height: 30vh;
  }
  @media (min-width: 48em) {
    .message-bot {
      --extra-margin: 3.5rem;
    }
  }

  .icon-bar {
    position: relative;
  }

  .icon-bar::before {
    content: '';
    position: absolute;
    bottom: 100%;
    left: 0;
    right: 0;
    height: 2rem;
    background: linear-gradient(to bottom, transparent, var(--cg-very-light-grey));
    pointer-events: none;
  }
</style>
