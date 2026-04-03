<script lang="ts">
  import { m } from '$lib/i18n/messages'
  import { fade } from 'svelte/transition'

  let {
    selectedPrompt = $bindable(''),
    display = $bindable(false)
  }: { selectedPrompt?: string; display?: boolean } = $props()

  const maxPrompts = 3

  function shuffle<T>(items: T[]): T[] {
    /**
     * Shuffles an array in place using the Fisher-Yates algorithm and returns a new array.
     * @param items The array of items to shuffle.
     * @returns A new array with the items shuffled.
     */
    const arr = [...items]
    for (let i = arr.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1))
      const tmp = arr[i]
      arr[i] = arr[j]
      arr[j] = tmp
    }
    return arr
  }

  function getAllPromptMessages(): string[] {
    /* Collect all prompt keys from i18n file that match the pattern "arenaHome.suggestions.prompts.{number}" and return their corresponding messages as an array of strings.
     */
    return Object.entries(m as unknown as Record<string, (...args: unknown[]) => unknown>)
      .filter(
        ([key, getter]) =>
          /^arenaHome\.suggestions\.prompts\.\d+$/.test(key) && typeof getter === 'function'
      )
      .map(([key, getter]) => ({
        index: Number(key.split('.').pop()),
        text: String(getter())
      }))
      .sort((a, b) => a.index - b.index)
      .map((entry) => entry.text)
  }

  const suggestions = $derived.by(() => {
    const allPrompts = getAllPromptMessages().filter((p) => p.trim() !== '')
    return shuffle(allPrompts).slice(0, Math.min(maxPrompts, allPrompts.length))
  })

  function selectPrompt(prompt: string) {
    selectedPrompt = prompt
  }
</script>

{#if display && suggestions.length > 0}
  <div class="prompt-suggestions" aria-label={m['arenaHome.suggestions.title']()}>
    {#each suggestions as prompt, idx (prompt)}
      {#if idx > 0}
        <hr
          class="separator m-0 p-0"
          aria-hidden="true"
          in:fade|global={{ duration: 180, delay: idx * 90 + 35 }}
        />
      {/if}

      <div role="listitem" in:fade|global={{ duration: 220, delay: idx * 90 }}>
        <button
          type="button"
          class="suggestion py-2 px-3 md:text-left w-full border-none bg-transparent text-center"
          onclick={() => selectPrompt(prompt)}
        >
          <span class="text-balance italic">{prompt}</span>
        </button>
      </div>
    {/each}
  </div>
{/if}

<style>
  .separator {
    border-top: 1px solid var(--border-default-grey);
  }

  div:has(.suggestion):first-child > .suggestion {
    border-top-left-radius: 1rem;
    border-top-right-radius: 1rem;
  }

  div:has(.suggestion):last-child > .suggestion {
    border-bottom-left-radius: 1rem;
    border-bottom-right-radius: 1rem;
  }

  .suggestion {
    color: var(--text-default-grey);
    cursor: pointer;
    transition:
      background-color 0.2s ease-out,
      font-weight 0.2s ease-out;
  }

  .suggestion:hover {
    background-color: var(--cg-light-grey);
    font-weight: 500;
  }
</style>
