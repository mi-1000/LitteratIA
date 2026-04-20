<script lang="ts">
  import { browser } from '$app/environment'
  import { Button, Modal } from '$components/dsfr'
  import Selector from '$components/Selector.svelte'
  import {
    APIDetailReactionGroups,
    APIGeneralReactions,
    APINegativeReactions,
    APIPositiveReactions,
    type APIDetailReactionGroup,
    type APIDetailReactionPref,
    type APIVoteReactionPref
  } from '$lib/chatService.svelte'
  import { useLocalStorage } from '$lib/helpers/useLocalStorage.svelte'
  import { m } from '$lib/i18n/messages'
  import { noop } from '$lib/utils/commons'
  import { tick } from 'svelte'

  type PanelReactionPref = APIDetailReactionPref | APIVoteReactionPref

  export interface LikePanelProps {
    id: string
    show?: boolean
    kind?: 'like' | 'dislike' | 'neutral'
    model: string
    selection: PanelReactionPref[]
    comment?: string
    disabled?: boolean
    showTooltip?: boolean
    mode?: 'react' | 'vote' | 'detail'
    onSelectionChange?: (selection: PanelReactionPref[]) => void
    onCommentChange?: (comment: string) => void
  }

  let {
    id,
    show = true,
    kind = 'neutral',
    model,
    selection = $bindable([]),
    comment = $bindable(''),
    disabled = false,
    showTooltip: isTouchScreen = browser ? window.matchMedia('(pointer: coarse)').matches : true, // Show tooltip on touch devices by default, otherwise trigger keyboard functionalities
    mode = 'react',
    onSelectionChange = noop,
    onCommentChange = noop
  }: LikePanelProps = $props()

  let like_panel: HTMLDivElement
  let hasBeenShown = $state(false)
  let helpContent = $state<{ title: string; description: string } | null>(null)

  async function openHelp(choice: ReactionChoice) {
    helpContent = { title: choice.label, description: choice.description ?? '' }

    await tick()

    const dialog = document.getElementById('label-tooltip-modal')
    // @ts-expect-error - DSFR is globally available
    if (dialog && window.dsfr) {
      // @ts-expect-error - DSFR is globally available
      window.dsfr(dialog).modal.disclose()
    }
  }

  const LABEL_SEED_STORAGE_KEY = 'litteratia:reaction-label-seed'
  const initialSeed = browser ? Math.floor(Math.random() * 2147483647) + 1 : 1
  const labelSeed = useLocalStorage<number>(LABEL_SEED_STORAGE_KEY, initialSeed, (value) =>
    Number.isInteger(value) && value > 0 ? value : initialSeed
  )

  const SHORTCUT_KEYS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')
  const LABEL_SELECTION_DEBOUNCE_MS = 300
  let selectionDebounceTimer: ReturnType<typeof setTimeout> | undefined

  type ReactionChoice = {
    value: PanelReactionPref
    label: string
    description?: string
  }

  function seededRandom(seed: number) {
    /**
     * @link{https://github.com/cprosche/mulberry32}
     */
    return () => {
      let t = (seed += 0x6d2b79f5)
      t = Math.imul(t ^ (t >>> 15), t | 1)
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296
    }
  }

  function shuffleWithSeed<T>(items: T[], seed: number): T[] {
    const result = [...items]
    const random = seededRandom(seed)

    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(random() * (i + 1))
      ;[result[i], result[j]] = [result[j], result[i]]
    }

    return result
  }

  type DetailGroup = {
    id: APIDetailReactionGroup
    label: string
    choices: { value: APIDetailReactionPref; label: string; description: string }[]
  }

  const detailReactionGroups = $derived.by<DetailGroup[]>(() => {
    const seed = labelSeed.value
    const shuffledGroups = shuffleWithSeed([...APIDetailReactionGroups], seed)

    // We shuffle both the order groups and labels within groups to mitigate position bias across users, but keep the order consistent across sessions for a same user
    return shuffledGroups.map((group, groupIndex) => ({
      id: group.id,
      label: m[`vote.choices.neutral.categories.${group.id}`](),
      choices: shuffleWithSeed([...group.reactions], seed + groupIndex + 1).map((value) => ({
        value,
        label: m[`vote.choices.neutral.${value}.label`](),
        description: m[`vote.choices.neutral.${value}.description`]()
      }))
    }))
  })

  const detailShortcuts = $derived.by(() => {
    const byValue: Partial<Record<APIDetailReactionPref, string>> = {}
    const byKey: Partial<Record<string, APIDetailReactionPref>> = {}

    const values = detailReactionGroups.flatMap((group) =>
      group.choices.map((choice) => choice.value)
    )
    const max = Math.min(values.length, SHORTCUT_KEYS.length)

    for (let index = 0; index < max; index++) {
      const key = SHORTCUT_KEYS[index]
      const value = values[index]
      byValue[value] = key
      byKey[key] = value
    }

    return { byValue, byKey }
  })

  function toggleChoice(value: PanelReactionPref) {
    if (disabled) return

    if (selection.includes(value)) {
      selection = selection.filter((v) => v !== value)
    } else {
      selection = [...selection, value]
    }

    emitSelectionChange(selection)
  }

  function emitSelectionChange(nextSelection: PanelReactionPref[]) {
    if (selectionDebounceTimer) {
      clearTimeout(selectionDebounceTimer)
    }

    const snapshot = [...nextSelection]
    selectionDebounceTimer = setTimeout(() => {
      onSelectionChange(snapshot)
      selectionDebounceTimer = undefined
    }, LABEL_SELECTION_DEBOUNCE_MS)
  }

  function clearSelection() {
    if (disabled || selection.length === 0) return

    selection = []
    emitSelectionChange(selection)
  }

  function handleKeydown(event: KeyboardEvent) {
    if (!show || disabled || mode !== 'detail' || helpContent !== null) return

    // If user is already typing, we don't trigger anything
    const target = event.target as HTMLElement | null
    const isTyping =
      target?.tagName === 'INPUT' || target?.tagName === 'TEXTAREA' || target?.isContentEditable

    if (isTyping) return
    if (event.ctrlKey || event.altKey || event.metaKey) return

    if (event.key === 'Escape') {
      if (selection.length > 0) {
        event.preventDefault()
        clearSelection()
      }
      return
    }

    const key = event.key.length === 1 ? event.key.toUpperCase() : ''
    const mappedChoice = detailShortcuts.byKey[key]
    if (!mappedChoice) return

    event.preventDefault()
    toggleChoice(mappedChoice)
  }

  const reactions = {
    like: {
      // TODO fix: only neutral labels still exist, others should be removed, but this introduces breaking changes
      label: m['vote.choices.positive.question'](),
      icon: 'i-bi-hand-thumbs-up-fill',
      choices: APIPositiveReactions.map((value) => ({
        value,
        label: m[`vote.choices.positive.${value}`]()
      })) as ReactionChoice[]
    },
    dislike: {
      label: m['vote.choices.negative.question'](),
      icon: 'i-bi-hand-thumbs-down-fill',
      choices: APINegativeReactions.map((value) => ({
        value,
        label: m[`vote.choices.negative.${value}`]()
      })) as ReactionChoice[]
    },
    neutral: {
      label: m['vote.choices.neutral.question'](),
      icon: 'i-bi-question-circle-fill',
      choices: APIGeneralReactions.map((value) => ({
        value,
        label: m[`vote.choices.neutral.${value}.label`](),
        description: m[`vote.choices.neutral.${value}.description`]()
      })) as ReactionChoice[]
    }
  }
  const reaction = $derived(reactions[kind] ?? reactions.neutral)

  function scrollIntoViewWithOffset(element: HTMLElement, offset: number) {
    // For offset 0 just consider a footer of 100px (really is 114px)
    offset = Math.max(100, offset || 0)
    const rect = element.getBoundingClientRect()
    const viewportHeight = window.visualViewport?.height || window.innerHeight

    const isVisible = rect.bottom <= viewportHeight - offset

    if (!isVisible) {
      // this not enough because margins so let's just add some extra
      // const scrollTop = window.scrollY + rect.height;
      const scrollTop = window.scrollY + rect.height + offset
      window.scrollTo({ top: scrollTop, behavior: 'smooth' })
    }
  }

  function checkVisibility() {
    if (!show || hasBeenShown || !like_panel) return

    const footer = document.getElementById('send-area')
    const footerHeight = footer ? footer.offsetHeight : 0
    const rect = like_panel.getBoundingClientRect()
    const appeared = !like_panel.classList.contains('hidden') && rect.height > 0

    if (appeared) {
      scrollIntoViewWithOffset(like_panel, footerHeight)
      hasBeenShown = true
    } else {
      requestAnimationFrame(checkVisibility)
    }
  }

  $effect(() => {
    if (show && !hasBeenShown && like_panel) {
      checkVisibility()
    } else if (!show) {
      hasBeenShown = false
    }
  })

  $effect(() => {
    return () => {
      if (selectionDebounceTimer) {
        clearTimeout(selectionDebounceTimer)
      }
    }
  })
</script>

<svelte:window onkeydown={handleKeydown} />

<div
  bind:this={like_panel}
  class="like-panel"
  class:hidden={show === false}
  class:flex={mode === 'vote'}
>
  {#if mode === 'detail'}
    <div class="w-full">
      <p class="mb-4! font-bold text-dark-grey md:text-base text-center text-[14px]">
        {m['vote.choices.neutral.question']()}
      </p>

      <div
        class="xl:w-2/3 gap-10 md:grid md:grid-cols-3 md:gap-0 md:justify-items-center mx-auto flex w-full max-w-[800px] flex-col"
      >
        {#each detailReactionGroups as group (group.id)}
          <section class="md:items-start md:w-fit flex w-full flex-col items-center">
            <p class="mb-3! md:text-left font-bold text-dark-grey text-sm w-full text-center!">
              {group.label}
            </p>
            <div
              class="gap-3 sm:flex sm:flex-row sm:justify-center md:flex-col grid w-fit grid-cols-2 max-[340px]:grid-cols-1"
            >
              {#each group.choices as choice (choice.value)}
                <!-- svelte-ignore a11y_click_events_have_key_events -->
                <div
                  role="button"
                  tabindex="0"
                  class={[
                    'min-w-0 p-2 like-choice detail-like-choice flex w-full items-center justify-between',
                    selection.includes(choice.value) ? 'is-selected' : ''
                  ]}
                  title={!isTouchScreen ? choice.description : undefined}
                  onclick={() => {
                    toggleChoice(choice.value)
                  }}
                >
                  <span
                    class="min-w-0 leading-tight tracking-tight px-1 md:text-[15px] lg:text-[16px] flex-1 text-center text-[14px] wrap-break-word hyphens-auto"
                  >
                    {choice.label}
                  </span>
                  <span class="ml-1 gap-1 flex shrink-0 items-center">
                    {#if isTouchScreen && choice.description}
                      <button
                        type="button"
                        title={m['words.detail']()}
                        class="i-bi-patch-question-fill text-gray h-4 w-4 transition-colors"
                        onclick={(e) => {
                          e.preventDefault()
                          e.stopPropagation() // Prevents from selecting the main button
                          openHelp(choice)
                        }}
                      >
                      </button>
                    {:else if detailShortcuts.byValue[choice.value]}
                      <kbd class="shortcut-key" aria-hidden="true">
                        {detailShortcuts.byValue[choice.value]}
                      </kbd>
                    {/if}
                  </span>
                </div>
              {/each}
            </div>
          </section>
        {/each}
      </div>

      {#if selection.length > 0 && !isTouchScreen}
        <div class="mt-4 text-center flex items-center justify-center gap-2">
          <button type="button" class="clear-selection-line" {disabled} onclick={clearSelection}>
            {m['vote.choices.clearSelection']()}
          </button>
          <kbd class="shortcut-key">{m['words.esc']()}</kbd>
        </div>
      {/if}
    </div>
  {:else}
    <p class="me-3! {mode === 'vote' ? 'mt-1! mb-0!' : 'mb-3!'} flex items-center justify-center">
      <i
        class="{reaction.icon} text-lg block"
        style="color: {kind === 'like'
          ? 'var(--cg-green)'
          : kind === 'neutral'
            ? 'var(--cg-grey)'
            : '#e1000f'}"
      ></i>
      <span
        class="ms-2 font-bold text-dark-grey md:text-base -translate-y-[0.75px] text-[14px]"
        class:sr-only={mode === 'vote'}
      >
        {reaction.label}
      </span>
    </p>
    <Selector
      id="{id}-selector"
      kind="checkbox"
      bind:value={selection}
      choices={reaction.choices}
      multiple
      {disabled}
      containerClass="flex flex-wrap gap-3 justify-center"
      choiceClass="like-choice"
      onChange={(nextSelection) => emitSelectionChange(nextSelection as PanelReactionPref[])}
    >
      {#snippet option(choice, props, _input)}
        <button
          type="button"
          {disabled}
          class={[props.class, selection.includes(choice.value) ? 'is-selected' : '']}
          onclick={() => {
            toggleChoice(choice.value)
          }}
        >
          {choice.label}
        </button>
      {/snippet}
      {#snippet extra(props)}
        {#if mode === 'react'}
          <button
            {disabled}
            class={[props.class, comment !== '' ? 'is-selected' : '']}
            data-fr-opened="false"
            aria-controls="{id}-modal"
            onclick={() => {
              // Focus textarea once DSFR modal finishes opening
              setTimeout(() => {
                document.querySelector<HTMLTextAreaElement>(`#${id}-modal textarea`)?.focus()
              }, 400)
            }}
          >
            {m['vote.choices.other']()}
          </button>
        {/if}
      {/snippet}
    </Selector>
  {/if}
</div>

{#if helpContent}
  <Modal
    id="label-tooltip-modal"
    titleId="label-tooltip-modal-title"
    sizeClass="fr-col-12 fr-col-md-6"
    onClose={() => (helpContent = null)}
  >
    <h1 id="label-tooltip-modal-title" class="fr-modal__title mb-4">
      {helpContent.title}
    </h1>
    <p class="text-gray leading-relaxed">
      {helpContent.description}
    </p>
  </Modal>
{/if}

<!-- Weird way to catch the comment if not validated but modal closed -->
{#if mode === 'react'}
  <dialog
    aria-labelledby="{id}-modal-label"
    id="{id}-modal"
    class="fr-modal"
    onblur={() => onCommentChange(comment)}
    onkeydown={(e) => {
      if (e.key === 'Escape') {
        onCommentChange(comment)
      }
    }}
  >
    <div class="fr-container fr-container--fluid fr-container-md">
      <div class="fr-grid-row fr-grid-row--center">
        <div class="fr-col-12 fr-col-md-8 fr-col-lg-6">
          <div class="fr-modal__body rounded-xl">
            <div class="fr-modal__header">
              <Button
                variant="tertiary-no-outline"
                text={m['words.close']()}
                title={m['closeModal']()}
                aria-controls="{id}-modal"
                class="fr-btn--close"
                onclick={() => onCommentChange(comment)}
              />
            </div>
            <div class="fr-modal__content">
              <p id="{id}-modal-label" class="modal-title">{m['vote.comment.add']()}</p>
              <div>
                <textarea
                  placeholder={model === 'both_equal'
                    ? m['vote.comment.placeholder_both_equal']()
                    : m['vote.comment.placeholder']({ model: model.toUpperCase() })}
                  class="fr-input"
                  rows="4"
                  bind:value={comment}
                  onkeydown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault()
                      onCommentChange(comment)
                      const dialog = document.getElementById(`${id}-modal`)
                      // @ts-expect-error - DSFR is globally available
                      if (dialog) window.dsfr(dialog).modal.conceal()
                    } else if (e.key === 'Escape') {
                      onCommentChange(comment)
                      const dialog = document.getElementById(`${id}-modal`)
                      // @ts-expect-error - DSFR is globally available
                      if (dialog) window.dsfr(dialog).modal.conceal()
                    }
                  }}
                  enterkeyhint="send"
                ></textarea>
                <Button
                  aria-controls="{id}-modal"
                  class="mt-4! mb-2! btn-color mx-auto! block!"
                  onclick={() => onCommentChange(comment)}
                >
                  {m['words.save']()}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </dialog>
{/if}

<style>
  .modal-title {
    font-weight: 700;
    font-size: 1.1em;
  }

  :global(.like-choice) {
    display: inline-flex;
    align-items: center;
    padding: 0.375rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 500;
    border-radius: 0.5rem;
    border: 1px solid var(--border-default-grey);
    background: var(--background-default-grey);
    color: var(--text-mention-grey);
    cursor: pointer;
    transition:
      border-color 0.3s,
      color 0.3s,
      background 0.3s;
    margin: 0;
    user-select: none;
  }

  :global(.like-choice:hover) {
    border-color: var(--text-action-high-blue-france);
    color: var(--text-action-high-blue-france);
  }

  :global(.like-choice.is-selected) {
    border-color: var(--blue-france-main-525);
    background: var(--blue-france-975-75);
    color: var(--blue-france-main-525);
    font-weight: 700;
    filter: drop-shadow(
      2px 2px 3px color-mix(in srgb, var(--border-default-grey), transparent 30%)
    );
  }

  :global(.like-choice.is-selected:active) {
    background: var(--hover-tint, var(--blue-france-975-75));
  }

  :global(.like-choice:focus-visible) {
    outline: 2px solid var(--outline-color);
    outline-offset: 2px;
  }

  :global(.like-choice:disabled) {
    opacity: 0.5;
    cursor: not-allowed;
  }

  :global(.detail-like-choice) {
    min-width: fit-content;
  }

  .shortcut-key {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 1.25rem;
    height: 1.25rem;
    padding: 0 0.25rem;
    border-radius: 0.25rem;
    border: 1px solid var(--border-default-grey);
    background: var(--background-alt-grey);
    color: var(--text-mention-grey);
    font-size: 0.7rem;
    font-weight: 700;
    line-height: 1;
  }

  .clear-selection-line {
    border: none;
    background: none;
    color: var(--text-mention-grey);
    font-size: 0.875rem;
    cursor: pointer;
  }

  .clear-selection-line:hover {
    color: var(--cg-blue-france-main-525-active);
    background: none;
  }

  .clear-selection-line:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
