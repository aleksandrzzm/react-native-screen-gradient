# react-native-screen-gradient

React native screen-space gradient

## Installation


```sh
npm install react-native-screen-gradient
```


## Usage


```tsx
import { ScreenGradient, GradientView } from "react-native-screen-gradient";

<ScreenGradient
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
  </ScrollView>
</ScreenGradient>
```

`ScreenGradient` defines one gradient in the coordinates of its own viewport
(`start`/`end` are fractions of its width/height). Every `GradientView` inside it
shows the part of that gradient that lies under its current on-screen position.
Scrolling is tracked natively; no JS scroll events are involved.

A `GradientView` outside a `ScreenGradient` draws nothing (with a warning in development).

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
