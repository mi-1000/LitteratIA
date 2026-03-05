<script lang="ts">
  import { noop } from '$lib/utils/commons'
  import type { Attachment } from 'svelte/attachments'

  export type TextAreaProps = {
    id: string
    label: string
    value: string
    hideLabel?: boolean
    minRows?: number
    maxRows?: number
    error?: string
    autofocus?: boolean
    autoscroll?: boolean
    el?: HTMLTextAreaElement
    class?: string
    onSubmit?: (value: string) => void
  } & Partial<Pick<HTMLTextAreaElement, 'disabled' | 'placeholder' | 'rows'>>

  let {
    id,
    label,
    value = $bindable(),
    hideLabel = false,
    rows = 1,
    minRows,
    maxRows = 15,
    error = $bindable(),
    autofocus = false,
    autoscroll = false,
    el = $bindable(),
    class: classNames = '',
    onSubmit = noop,
    ...nativeTextAreaProps
  }: TextAreaProps = $props()

  const baseRows = minRows ?? rows

  $effect(() => {
    if (!el) return
    // Access value to establish reactivity
    void value

    // Shrink to minimum to measure true scrollHeight
    el.rows = baseRows
    const lineHeight = parseFloat(getComputedStyle(el).lineHeight) || 24
    const needed = Math.ceil(el.scrollHeight / lineHeight)
    rows = Math.max(baseRows, Math.min(needed, maxRows))
    el.rows = rows
  })

  const updateAuto: Attachment<HTMLTextAreaElement> = (el) => {
    if (autofocus) el.focus()
    if (autoscroll) el.scrollTo(0, el.scrollHeight)
  }

  const onkeydown = (e: KeyboardEvent) => {
    error = undefined
    if (e.key === 'Enter' && !e.shiftKey) {
      onSubmit(value)
    }
  }
</script>

<div class={['fr-input-group', classNames, { 'fr-input-group--error': !!error }]}>
  <label for={id} class={['fr-label', { 'hidden!': hideLabel }]}>{label}</label>
  <textarea
    {id}
    data-testid="textbox"
    bind:value
    bind:this={el}
    {rows}
    class="fr-input cg-border rounded-md! bg-white! md:min-h-10! border-solid!"
    {...nativeTextAreaProps}
    aria-describedby="messages-{id}"
    {onkeydown}
    {@attach updateAuto}
  ></textarea>
  <div class="fr-messages-group" id="messages-{id}" aria-live="polite">
    {#if error}
      <p class="fr-message fr-message--error" id="messages-{id}-error">{error}</p>
    {/if}
  </div>
</div>

<style lang="postcss">
  .fr-input {
    --border-plain-grey: var(--blue-france-main-525);
  }
</style>
