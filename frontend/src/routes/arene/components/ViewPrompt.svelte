<script lang="ts">
  import { Button } from '$components/dsfr'
  import TextPrompt from '$components/TextPrompt.svelte'
  import type { APIModeAndPromptData } from '$lib/chatService.svelte'
  import { runChatBots } from '$lib/chatService.svelte'
  import { useLocalStorage } from '$lib/helpers/useLocalStorage.svelte'
  import { m } from '$lib/i18n/messages.js'
  import { getModelsContext } from '$lib/models'
  import { PromptSuggestion } from '.'

  let promptEl = $state<HTMLTextAreaElement>()
  let promptAreaEl = $state<HTMLDivElement>()
  let disabled = $state(false)
  let isPromptFocused = $state(false)
  let focusTick = $state(0)
  let prompt = $state('')
  let promptError = $state<string>()

  const models = getModelsContext().models.filter((model) => model.status === 'enabled')
  const mode = useLocalStorage<APIModeAndPromptData['mode']>('mode', 'random')
  const modelsSelection = useLocalStorage<string[]>('customModelsSelection', [], (parsed) => {
    if (Array.isArray(parsed) && parsed.every((item) => typeof item === 'string')) {
      const availableModelIds = new Set(models.map((m) => m.id))
      return parsed.filter((id) => availableModelIds.has(id))
    }
    return []
  })

  async function dispatchSubmit(): Promise<void> {
    disabled = true
    const validationError = await runChatBots({
      mode: mode.value,
      custom_models_selection: modelsSelection.value,
      prompt_value: prompt
    })
    if (validationError) {
      promptError = validationError
      disabled = false
    }
  }

  function onPromptAreaFocusIn(event: FocusEvent) {
    // On récupère l'élément qui avait le focus juste avant
    const previous = event.relatedTarget as Node | null;

    // Si l'élément précédent était DÉJÀ dans la zone de prompt, 
    // on ne fait rien (on ne veut pas re-mélanger)
    if (promptAreaEl && previous && promptAreaEl.contains(previous)) return;

    isPromptFocused = true;
    focusTick += 1; // Le shuffle ne se lancera qu'en entrant réellement dans la zone
  }

  function onPromptAreaFocusOut(event: FocusEvent) {
    const next = event.relatedTarget as Node | null
    if (promptAreaEl && next && promptAreaEl.contains(next)) return
    isPromptFocused = false
  }
</script>

<div id="prompt-area" class="fr-container py-10 md:py-24">
  <div class="fr-col-xl-8 m-auto">
    <h3 class="mb-0! text-center">
      {m['arenaHome.title']()}
    </h3>
    <div
      bind:this={promptAreaEl}
      class="gap-3 py-5 md:grid-flow-row-dense md:grid-cols-6 grid"
      onfocusin={onPromptAreaFocusIn}
      onfocusout={onPromptAreaFocusOut}
    >
      <div class="md:order-none md:col-span-full order-1">
        <TextPrompt
          id="initial-prompt"
          bind:el={promptEl}
          bind:value={prompt}
          label={m['arenaHome.prompt.label']()}
          placeholder={m['arenaHome.prompt.placeholder']()}
          bind:error={promptError}
          {disabled}
          hideLabel
          rows={4}
          onSubmit={dispatchSubmit}
        />
      </div>

      <Button
        type="submit"
        text={m['words.send']()}
        disabled={prompt == '' || !!promptError || disabled}
        class="md:w-auto! md:order-none md:col-span-full md:justify-self-center btn-color order-2 w-full! min-w-[130px]"
        onclick={() => dispatchSubmit()}
        title={m['words.send']()}
        aria-label={m['words.send']()}
      />

      <div class="pb-10 md:order-none md:col-span-full order-3">
        <PromptSuggestion bind:selectedPrompt={prompt} display={isPromptFocused} focusTick={focusTick} />
      </div>
    </div>
  </div>
</div>
