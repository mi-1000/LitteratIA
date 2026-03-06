import { ARCHS, LICENSES, MAYBE_ARCHS, MODELS, ORGANISATIONS } from '$lib/generated/models'
import { getLocale } from '$lib/i18n/runtime'
import { getContext, setContext } from 'svelte'
import { m } from './i18n/messages'

// Format parameter counts: multiply input (assumed in billions) by 1_000_000_000
// and return a localized, human-friendly string with unit suffixes.
export function formatParams(countInBillions: number, localeOverride?: string) {
  const value = Number(countInBillions) * 1_000_000_000
  const locale = (localeOverride ?? (typeof getLocale === 'function' ? getLocale() : undefined) ?? 'fr').toString()
  const abs = Math.abs(value)
  const unitMillion = m['models.parameters_units.million']()
  const unitBillion = m['models.parameters_units.billion']()
  const unitTrillion = m['models.parameters_units.trillion']()

  let divisor = 1
  let unit = ''
  if (abs >= 1e12) {
    divisor = 1e12
    unit = unitTrillion
  } else if (abs >= 1e9) {
    divisor = 1e9
    unit = unitBillion
  } else if (abs >= 1e6) {
    divisor = 1e6
    unit = unitMillion
  } else {
    // less than 1 million: show plain number localized
    return new Intl.NumberFormat(locale).format(value)
  }

  const scaled = value / divisor
  const hasFraction = Math.abs(scaled - Math.trunc(scaled)) >= 0.1
  const nf = new Intl.NumberFormat(locale, { maximumFractionDigits: hasFraction ? 1 : 0 })
  const formatted = nf.format(scaled)
  const sep = locale.startsWith('fr') ? '\u00A0' : ''
  return `${formatted}${sep}${unit}`
}

export const SIZES = ['XS', 'S', 'M', 'L', 'XL'] as const
export const CONSO_SIZES = ['S', 'M', 'L'] as const

export type Sizes = (typeof SIZES)[number]
export type ConsoSizes = (typeof CONSO_SIZES)[number]
export type Archs = (typeof ARCHS)[number]
export type MaybeArchs = (typeof MAYBE_ARCHS)[number]
export type AllArchs = Archs | MaybeArchs
export type License = (typeof LICENSES)[number]
export type Organisation = (typeof ORGANISATIONS)[number]
export type Model = (typeof MODELS)[number]

interface DatasetData {
  elo: number
  score_p2_5: number
  score_p97_5: number
  rank: number
  rank_p2_5: number
  rank_p97_5: number
  n_match: number
  mean_win_prob: number
  win_rate: number
  trust_range: [number, number]
}

interface PreferencesData {
  positive_prefs_ratio: number
  total_prefs: number
  // Positive count
  useful: number
  clear_formatting: number
  complete: number
  creative: number
  // Negative count
  incorrect: number
  instructions_not_followed: number
  superficial: number
}

export interface APIBotModel {
  new: boolean
  status: 'archived' | 'enabled'
  id: string
  simple_name: Model
  organisation: Organisation
  icon_path: string
  distribution: 'api-only' | 'open-weights' | 'fully-open-source'
  license: License
  reuse: boolean
  commercial_use: boolean | null
  release_date: string
  params: number
  active_params: number | null
  friendly_size: Sizes
  arch: AllArchs
  reasoning: boolean | 'hybrid'
  quantization: 'q4' | 'q8' | null
  required_ram: number
  url: string | null // FIXME required?
  // conditions: 'free' | 'copyleft' | 'restricted'
  wh_per_million_token: number
  data: DatasetData | null
  prefs: PreferencesData | null
}
export type APIData = { data_timestamp: number; models: APIBotModel[] }
export type Data = { lastUpdateDate: string; models: BotModel[] }
export type BotModel = ReturnType<typeof parseModel>
export type BotModelWithData = BotModel & { data: DatasetData; prefs: PreferencesData }

function isMaybeArch(arch: AllArchs): arch is MaybeArchs {
  return MAYBE_ARCHS.includes(arch as MaybeArchs)
}

export function parseModel(model: APIBotModel) {
  const params_display = formatParams(model.params)
  const getMsg = (key: string) => {
    // defensive: messages generated map may not contain every dynamic key
    const fn = (m as any)[key]
    return typeof fn === 'function' ? fn() : ''
  }

  return {
    ...model,
    params_display,
    consumption_wh: Math.round(model.wh_per_million_token / 1000),
    desc: getMsg(`generated.models.${model.simple_name}.desc`),
    sizeDesc: getMsg(`generated.models.${model.simple_name}.size_desc`),
    fyi: getMsg(`generated.models.${model.simple_name}.fyi`),
    licenseInfos:
      model.license === 'proprietary'
        ? {
            desc: getMsg(`generated.licenses.proprio.${model.organisation}.license_desc`),
            reuseSpecificities: getMsg(
              `generated.licenses.proprio.${model.organisation}.reuse_specificities`
            ),
            commercialUseSpecificities: getMsg(
              `generated.licenses.proprio.${model.organisation}.commercial_use_specificities`
            )
          }
        : {
            desc: getMsg(`generated.licenses.os.${model.license}.license_desc`),
            reuseSpecificities: getMsg(
              `generated.licenses.os.${model.license}.reuse_specificities`
            ),
            commercialUseSpecificities: getMsg(
              `generated.licenses.os.${model.license}.commercial_use_specificities`
            )
          },
    badges: {
      license: {
        'fully-open-source': {
          id: `model-os-${model.id}`,
          variant: 'green' as const,
          text: m['models.licenses.type.openSource'](),
          tooltip: m['models.openWeight.tooltips.openSource']()
        },
        'open-weights': {
          id: `model-ow-${model.id}`,
          variant: 'yellow' as const,
          text: m['models.licenses.type.semiOpen'](),
          tooltip: m['models.openWeight.tooltips.openWeight']()
        },
        'api-only': {
          id: `model-proprietary-${model.id}`,
          variant: 'orange' as const,
          text: m['models.licenses.type.proprietary']()
        }
      }[model.distribution],
      releaseDate: model.release_date
        ? ({
            variant: '' as const,
            text: m['models.release']({ date: model.release_date })
          } as const)
        : null,
      licenseName: {
        variant: '' as const,
        text:
          model.license === 'proprietary' ? m['models.licenses.type.proprietary']() : model.license
      },
      size: {
        id: `model-parameters-${model.id}`,
        variant: 'info' as const,
        text:
          model.distribution === 'open-weights' || model.distribution === 'fully-open-source'
            ? `${params_display} ${m['models.parameters_suffix']()}`
            : m['models.size.estimated']({ size: model.friendly_size }),
        tooltip:
          model.distribution === 'api-only' ? m['models.openWeight.tooltips.params']() : undefined
      },
      arch: {
        id: `model-arch-${model.id}`,
        variant: 'yellow' as const,
        text: getMsg(
          `generated.archs.${isMaybeArch(model.arch) ? 'na' : model.arch}.title`
        ),
        tooltip: getMsg(
          `generated.archs.${isMaybeArch(model.arch) ? 'na' : model.arch}.desc`
        )
      },
      reasoning: model.reasoning ? ({ variant: '', text: 'Modèle de raisonnement' } as const) : null
    },
    search: (['id', 'simple_name', 'organisation'] as const)
      .map((key) => model[key].toLowerCase())
      .join(' ')
  }
}

export function setModelsContext(data: APIData) {
  setContext('data', {
    lastUpdateDate: new Date(data.data_timestamp * 1000).toLocaleDateString(),
    models: data.models.map((model) => parseModel(model))
  })
}

export function getModelsContext() {
  return getContext<Data>('data')
}

export function getModelsWithDataContext() {
  const { models, ...data } = getContext<Data>('data')
  return {
    ...data,
    models: (
      models.filter((m) => {
        if (m.data == null) return false
        if (m.prefs == null) return false
        if (m.data.trust_range[0] > 10 || m.data.trust_range[1] > 10) return false
        return true
      }) as BotModelWithData[]
    )
      .sort((a, b) => a.data.rank - b.data.rank)
      .map((m, i) => ({
        ...m,
        data: {
          ...m.data,
          rank: i + 1
        }
      }))
  }
}
