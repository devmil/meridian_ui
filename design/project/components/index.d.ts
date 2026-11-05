// Meridian preview components (window.Meridian). They mirror the Flutter widgets in
// meridian_ui (MeridianButton, MeridianIsland, …); props are named after the Dart ones.
import type * as React from 'react';

type Children = { children?: React.ReactNode };
export type IconName = string; // a Lucide name from the Icons group, for example 'circle-check'

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> { variant?: 'primary' | 'secondary' | 'quiet' | 'danger' | 'danger-quiet'; size?: 'sm'; icon?: IconName; trailingIcon?: IconName; shortcut?: string[]; loading?: boolean; expand?: boolean }
export declare function Button(props: ButtonProps): React.ReactElement;
export interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> { icon: IconName; label: string; size?: 'sm'; active?: boolean; onGround?: boolean }
export declare function IconButton(props: IconButtonProps): React.ReactElement;
export interface ToolbarButtonProps { icon: IconName; label: string; badge?: number; menu?: boolean; showLabel?: boolean; disabled?: boolean }
export declare function ToolbarButton(props: ToolbarButtonProps): React.ReactElement;

export interface TextFieldProps { label?: string; placeholder?: string; value?: string; icon?: IconName; trailing?: string; variant?: 'standard' | 'search'; size?: 'sm'; error?: string; message?: string; multiline?: boolean; rows?: number; monospace?: boolean; width?: number; type?: string }
export declare function TextField(props: TextFieldProps): React.ReactElement;
export interface CheckboxProps extends Children { checked?: boolean; mixed?: boolean; disabled?: boolean; description?: string }
export declare function Checkbox(props: CheckboxProps): React.ReactElement;
export interface RadioProps extends Children { checked?: boolean; disabled?: boolean; description?: string }
export declare function Radio(props: RadioProps): React.ReactElement;
export interface RadioGroupProps { label: string; value: string; options: { value: string; label: string; description?: string }[] }
export declare function RadioGroup(props: RadioGroupProps): React.ReactElement;
export interface SwitchProps extends Children { checked?: boolean; disabled?: boolean; hideLabel?: boolean }
export declare function Switch(props: SwitchProps): React.ReactElement;
export interface SegmentedProps { label: string; value?: string; size?: 'sm'; expand?: boolean; options: { value: string; label?: string; icon?: IconName; tooltip?: string }[] }
export declare function Segmented(props: SegmentedProps): React.ReactElement;
export interface SliderProps { label: string; value?: number; width?: number }
export declare function Slider(props: SliderProps): React.ReactElement;
export interface RangeSliderProps { startLabel: string; endLabel: string; start?: number; end?: number; width?: number }
export declare function RangeSlider(props: RangeSliderProps): React.ReactElement;
export interface SelectProps { value: string; label?: string; width?: number }
export declare function Select(props: SelectProps): React.ReactElement;

export type MenuEntry = { type: 'divider' } | { type: 'header'; label: string } | { label: string; icon?: IconName; shortcut?: string[]; hint?: string; danger?: boolean; disabled?: boolean; checked?: boolean; highlighted?: boolean };
export declare function Menu(props: { items: MenuEntry[]; width?: number }): React.ReactElement;

export interface TabsProps { tabs: { label: string; icon?: IconName; count?: number; dirty?: boolean }[]; index?: number; variant?: 'underline' | 'pill'; closable?: boolean }
export declare function Tabs(props: TabsProps): React.ReactElement;
export interface TabStripGroup { id: string | number; color: string; name?: string; icon?: IconName; collapsed?: boolean }
export interface TabStripProps { tabs: { label: string; icon?: IconName; dirty?: boolean; group?: string | number }[]; groups?: TabStripGroup[]; active?: string }
export declare function TabStrip(props: TabStripProps): React.ReactElement;
export interface NavSectionProps extends Children { title: string; count?: number; action?: IconName; actionLabel?: string }
export declare function NavSection(props: NavSectionProps): React.ReactElement;
export interface NavRowProps { name: string; icon?: IconName; iconColor?: string; count?: number; countTone?: CountTone; depth?: number; expandable?: boolean; open?: boolean; current?: boolean; state?: 'selected' | 'focused' }
export declare function NavRow(props: NavRowProps): React.ReactElement;
export interface ListRowProps { title: string; subtitle?: string; meta?: string; avatar?: string; icon?: IconName; twoLine?: boolean; emphasized?: boolean; dimmed?: boolean; state?: 'selected' | 'focused'; actions?: { icon: IconName; label: string }[]; trailing?: React.ReactNode }
export declare function ListRow(props: ListRowProps): React.ReactElement;
export declare function Steps(props: { steps: string[]; current: number; label?: string; compact?: boolean; width?: number }): React.ReactElement;
export interface AppBarProps { title: string; leading?: IconName; leadingLabel?: string; actions?: { icon: IconName; label: string }[]; elevated?: boolean }
export declare function AppBar(props: AppBarProps): React.ReactElement;

export declare function Kbd(props: { keys: string[] }): React.ReactElement;
export type CountTone = 'neutral' | 'accent' | 'attention' | 'danger' | 'quiet';
export declare function Count(props: Children & { tone?: CountTone }): React.ReactElement;
export declare function Avatar(props: { name: string; colorKey?: string; size?: 'md' | 'lg' }): React.ReactElement;
export interface ChipProps extends Children { icon?: IconName; dot?: string; tone?: 'neutral' | 'accent' | 'success' | 'warning' | 'danger' | 'attention'; selected?: boolean; removable?: boolean; onClick?: () => void }
export declare function Chip(props: ChipProps): React.ReactElement;
export declare function StatusDot(props: Children & { tone?: 'accent' | 'success' | 'warning' | 'danger' | 'attention'; halo?: boolean }): React.ReactElement;

export declare function Spinner(): React.ReactElement;
export declare function ProgressBar(props: { value?: number; track?: boolean; width?: number; label?: string }): React.ReactElement;
export declare function Meter(props: { value: number; warningAt?: number; dangerAt?: number; width?: number }): React.ReactElement;
export declare function Waveform(props: { peaks: readonly number[]; progress?: number | null; height?: number; width?: number; rtl?: boolean }): React.ReactElement;
export declare function Banner(props: Children & { tone?: 'info' | 'success' | 'warning' | 'attention' | 'error'; title?: string; icon?: IconName; actions?: React.ReactNode; dismissible?: boolean }): React.ReactElement;
export declare function Toast(props: Children & { tone?: 'success' | 'warning' | 'error'; action?: string }): React.ReactElement;
export declare function EmptyState(props: Children & { title: string; icon?: IconName; action?: React.ReactNode; headline?: boolean }): React.ReactElement;
export declare function Skeleton(props: { width?: number | string; height?: number }): React.ReactElement;

export declare function Island(props: Children & { title?: string; subtitle?: string; actions?: React.ReactNode; focused?: boolean; style?: React.CSSProperties; bodyStyle?: React.CSSProperties }): React.ReactElement;
export declare function Disclosure(props: Children & { title: string; open?: boolean }): React.ReactElement;
export declare function Dialog(props: Children & { title: string; description?: string; aside?: React.ReactNode; actions: React.ReactNode }): React.ReactElement;
export declare function Sheet(props: Children & { title?: string; actions?: React.ReactNode }): React.ReactElement;
export declare function Panel(props: Children & { title: string; actions?: React.ReactNode }): React.ReactElement;
export declare function SettingsDialog(props: Children & { title: string; pages: readonly { label: string; icon?: IconName }[]; page: string; description?: string }): React.ReactElement;
export declare function SettingsGroup(props: Children & { title?: string; stacked?: boolean }): React.ReactElement;
export declare function SettingsRow(props: Children & { label: string; help?: string }): React.ReactElement;
export declare function Icon(props: { name: IconName; size?: 'sm'; stroke?: number; className?: string; style?: React.CSSProperties }): React.ReactElement;

declare global { interface Window { Meridian: typeof import('./index') } }
