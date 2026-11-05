# Waveform

A bounded decorative audio peak envelope. Flutter: `MeridianWaveform`.

- Provide at most1,024 finite normalized `peaks` (0–1), in chronological order. The consumer owns decoding, aggregation and loading/error state; do not pass PCM or one sample per audio frame. Input is copied so later caller mutation cannot change an existing picture.
- Optional confirmed `progress` (0–1) fills the elapsed portion with `accent`; the rest uses `ink-muted`. Reading direction determines the timeline origin. The waveform uses the available bounded width and `waveformHeight`, or a caller-provided height. It never animates incoming data or delays playback.
- This is decorative, has no pointer target, keyboard focus, label or slider role. Provide a separately labelled Slider or RangeSlider for seeking/trimming and announce those confirmed times. Loading, unavailable and silent audio are distinct consumer states; an empty peak list paints no data.
- Peak allocation and painting are bounded; rendering does not decode media or infer frame/sample rates. Brand/density/reduced-motion behavior follows shared tokens. It is not a spectrogram, editor, recorder or interactive timeline.
