# react-native-screen-gradient

React native screen-space gradient

## Installation


```sh
npm install react-native-screen-gradient
```


## Usage


```tsx
import {
  GradientHost,
  GradientView,
  GradientMaskSvg,
  Path,
} from "react-native-screen-gradient";

<GradientHost
  colors={["#ff0000", "#ffff00"]}
  locations={[0, 1]}
  start={{ x: 0, y: 0 }}
  end={{ x: 0, y: 1 }}
  style={{ flex: 1 }}
>
  <ScrollView>
    <GradientView>
      <Text>Hello</Text>
    </GradientView>

    <GradientMaskSvg viewBox="0 0 24 24" style={{ width: 48, height: 48 }}>
      <Path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </GradientMaskSvg>
  </ScrollView>
</GradientHost>
```

`GradientHost` defines one gradient in its **own** coordinates (`start`/`end`
are fractions of its width/height, not of the screen). Every `GradientView` /
`GradientMaskSvg` inside it shows the part of that gradient that lies under its
current position in the host. Scrolling is tracked natively; no JS scroll events
are involved.

### Named hosts

`<GradientHost host="card">` names a host (default `"main"`). `GradientView` and
`GradientMaskSvg` use the nearest **ancestor** host whose name matches their
`hostName` (default `"main"`), so an inner host does not hide an outer one:

```tsx
<GradientHost colors={screenColors}>
  <GradientHost host="card" colors={cardColors}>
    <GradientView hostName="card" />   {/* card gradient */}
    <GradientView />                   {/* screen ("main") gradient */}
  </GradientHost>
</GradientHost>
```

A view without a matching ancestor host draws nothing (with a warning in development).

### GradientMaskSvg

Fills and/or strokes its `<Path>` children with the host gradient. Supported
path props: `d` (full SVG path syntax), `fill` (`"none"` disables fill),
`fillRule`, `stroke` (any value except `"none"` enables stroke), `strokeWidth`,
`strokeLinecap`, `strokeLinejoin`, `strokeMiterlimit`. Colors are ignored — the
gradient is the paint. `viewBox` scales like SVG's default `xMidYMid meet`.
`Path` from `react-native-svg` works as a child too; only direct children (and
fragments) are read.

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
