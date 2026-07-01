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

  export type MessageBotProps = {
    message: AssistantMessage
    index: number
    disabled?: boolean
    onReactionChange: OnReactionFn
  }

  export type MessageBotExtra = {
    showModelName?: boolean | 'showA' | 'showB'
    side?: 'A' | 'B'
    invertModelLabels?: boolean
  }

  let {
    message,
    index,
    disabled = false,
    onReactionChange,
    showModelName: initialShowModelName = false,
    side = 'A',
    invertModelLabels = false
  }: MessageBotProps & MessageBotExtra = $props()

  let showModelName = $state(initialShowModelName)

  const displaySide = invertModelLabels
    ? side.toLowerCase() === 'a'
      ? 'b'
      : 'a'
    : side.toLowerCase()

  function shouldShowFor(modelSide: string) {
    const val = showModelName as any
    const s = String(modelSide).toLowerCase()
    if (val === true) return true
    if (val === 'showA' && s === 'a') return true
    if (val === 'showB' && s === 'b') return true
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
    // decide which model side we display (swap if invertModelLabels)
    const displaySide = invertModelLabels
      ? side.toLowerCase() === 'a'
        ? 'b'
        : 'a'
      : side.toLowerCase()

    // If anonymized for the target model side, return explicit physical side label (A/B)
    if (!shouldShowFor(displaySide))
      return { provider: '', model: m['chatbot.modelAnon']({ side: side.toUpperCase() }) }

    // Prefer backend-provided mapping if available
    try {
      const map = (arena as any).chat?.model_map
      const sideKey = displaySide
      if (map && map[sideKey]) {
        const modelId = map[sideKey]
        try {
          const ctx = getModelsContext()
          if (ctx && ctx.models) {
            const found = ctx.models.find(
              (mm: any) => mm.id === modelId || mm.simple_name === modelId
            )
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

    // Try i18n mapping by logical side (a/b) like the vote UI does
    try {
      const fn = (m as any)[`models.names.${displaySide}`]
      if (typeof fn === 'function') {
        const v = fn()
        if (v && v.toString().trim() !== '') return splitModelId(String(v))
      }
    } catch (e) {
      // ignore
    }

    // Fallback to prettified side key (keeps behavior consistent with vote UI)
    return splitModelId(prettifyBotId(displaySide))
  }

  // Return HTML string with provider in italic and model in bold.
  function getModelHtml(): string {
    const parts = getModelParts()
    // sanitize parts separately to avoid accidental tags in provider/model
    const prov = parts.provider
      ? `<span class="provider-name">${escapeHtml(parts.provider)}/</span>`
      : ''
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
    index: index * 2 + (side.toLowerCase() === 'a' ? 1 : 2),
    bot: message.metadata.bot,
    rating: null,
    prefs: [],
    comment: '',
    value: message.content
  })

  let modelsReady = $derived(
    arena.chat?.a?.status === 'complete' && arena.chat?.b?.status === 'complete'
  )

  function toggleModelNameVisibility() {
    showModelName = !showModelName
  }

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
    class={`message-bot cg-border rounded-lg! bg-white relative flex h-full flex-col overflow-hidden message-bot-${side.toLowerCase()}`}
  >
    <div
      class="top-0 pb-5 pt-7 model-label bg-white px-5 sticky z-10 flex items-center"
      style="cursor: pointer;"
      onclick={toggleModelNameVisibility}
      role="button"
      tabindex="0"
    >
      <div class="c-bot-disk-{bot}"></div>
      <h3 class="ms-2! mb-0! text-base! flex-1 text-left">
        {#if !shouldShowFor(displaySide)}
          {m['chatbot.modelAnon']({ side: side.toUpperCase() })}
        {:else}
          {@html getModelHtml()}
        {/if}
      </h3>
    </div>

    <div class="px-5 flex-1 overflow-y-auto model-chat-content-side-{side.toLowerCase()}">
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

    <div class="icon-bar bg-white px-5 py-3 bottom-0 sticky z-2 flex shrink-0">
      <Copy value={message.content} />

      <div class="gap-2 ms-auto flex">
        <!-- Like/Dislike buttons removed — per-round merged panel used instead -->
      </div>
    </div>
  </div>
  <!-- per-message panels are now merged in GroupedMessages -->
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
    background: linear-gradient(
      to bottom,
      transparent,
      color-mix(in srgb, var(--cg-bg-white) 50%, transparent)
    );
    pointer-events: none;
  }
</style>
