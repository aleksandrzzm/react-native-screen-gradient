import { type ComponentRef, useEffect, useRef, useState } from 'react';
import {
  FlatList,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { GradientView, ScreenGradient } from 'react-native-screen-gradient';

// Y=0 -> red, Y=50% -> purple, Y=100% -> yellow (in ScreenGradient viewport coordinates).
const COLORS = ['#ff0000', '#800080', '#ffff00'];
const LOCATIONS = [0, 0.5, 1];

const GRADIENT_HEIGHTS = [100, 200, 50, 300];
const SPACER = 240;

type Mode = 'scroll' | 'inverted';

export default function App() {
  const [mode, setMode] = useState<Mode>('scroll');

  return (
    <View style={styles.root}>
      <View style={styles.tabs}>
        <Button
          title="ScrollView"
          active={mode === 'scroll'}
          onPress={() => setMode('scroll')}
        />
        <Button
          title="Inverted FlatList"
          active={mode === 'inverted'}
          onPress={() => setMode('inverted')}
        />
      </View>

      <ScreenGradient
        colors={COLORS}
        locations={LOCATIONS}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
        style={styles.screen}
      >
        {mode === 'scroll' ? <ScrollExample /> : <InvertedListExample />}

        {/* Static reference strip: shows the whole gradient in place. Every scrolling
            GradientView must match the strip's color at the same screen Y. */}
        <GradientView pointerEvents="none" style={styles.referenceStrip} />
      </ScreenGradient>
    </View>
  );
}

function ScrollExample() {
  const scrollRef = useRef<ComponentRef<typeof ScrollView>>(null);
  const pingPong = usePingPong((to) =>
    scrollRef.current?.scrollTo({ y: to ? 2000 : 0, animated: true })
  );

  return (
    <>
      <ScrollView ref={scrollRef} style={styles.fill}>
        {GRADIENT_HEIGHTS.map((height, index) => (
          <View key={height}>
            <View style={styles.spacer}>
              <Text style={styles.spacerText}>spacer {index + 1}</Text>
            </View>
            <GradientView
              style={[
                styles.gradientView,
                { height },
                index === 1 && styles.rounded,
              ]}
            >
              <Text style={styles.label}>GradientView height={height}</Text>
            </GradientView>
          </View>
        ))}
        <View style={styles.spacer} />
      </ScrollView>

      <View style={styles.controls}>
        <Button
          title="scrollTo 150"
          onPress={() =>
            scrollRef.current?.scrollTo({ y: 150, animated: true })
          }
        />
        <Button
          title="scrollToEnd"
          onPress={() => scrollRef.current?.scrollToEnd({ animated: true })}
        />
        <Button
          title="top"
          onPress={() => scrollRef.current?.scrollTo({ y: 0, animated: true })}
        />
        <Button
          title={pingPong.running ? 'stop' : 'ping-pong'}
          onPress={pingPong.toggle}
        />
      </View>
    </>
  );
}

const LIST_DATA = Array.from({ length: 200 }, (_, i) => ({
  key: String(i),
  height: GRADIENT_HEIGHTS[i % GRADIENT_HEIGHTS.length]!,
}));

function InvertedListExample() {
  const listRef = useRef<FlatList<(typeof LIST_DATA)[number]>>(null);
  const pingPong = usePingPong((to) =>
    listRef.current?.scrollToOffset({ offset: to ? 6000 : 0, animated: true })
  );

  return (
    <>
      <FlatList
        ref={listRef}
        inverted
        removeClippedSubviews
        style={styles.fill}
        data={LIST_DATA}
        renderItem={({ item }) => (
          <GradientView
            style={[
              styles.gradientView,
              styles.listItem,
              { height: item.height },
            ]}
          >
            <Text style={styles.label}>
              #{item.key} height={item.height}
            </Text>
          </GradientView>
        )}
      />
      <View style={styles.controls}>
        <Button
          title="offset 3000"
          onPress={() =>
            listRef.current?.scrollToOffset({ offset: 3000, animated: true })
          }
        />
        <Button
          title="bottom"
          onPress={() =>
            listRef.current?.scrollToOffset({ offset: 0, animated: true })
          }
        />
        <Button
          title={pingPong.running ? 'stop' : 'ping-pong'}
          onPress={pingPong.toggle}
        />
      </View>
    </>
  );
}

/**
 * Test driver only: issues animated scroll *commands* back and forth. It never reads the
 * scroll position; the gradient positioning is entirely native.
 */
function usePingPong(scrollTo: (toEnd: boolean) => void) {
  const [running, setRunning] = useState(false);
  const scrollToRef = useRef(scrollTo);
  scrollToRef.current = scrollTo;

  useEffect(() => {
    if (!running) {
      return undefined;
    }
    let toEnd = true;
    scrollToRef.current(toEnd);
    const id = setInterval(() => {
      toEnd = !toEnd;
      scrollToRef.current(toEnd);
    }, 700);
    return () => clearInterval(id);
  }, [running]);

  return { running, toggle: () => setRunning((value) => !value) };
}

function Button({
  title,
  onPress,
  active,
}: {
  title: string;
  onPress: () => void;
  active?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.button, active && styles.buttonActive]}
    >
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#111',
    paddingTop: 48,
  },
  tabs: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    paddingBottom: 8,
  },
  screen: {
    flex: 1,
    backgroundColor: '#222',
  },
  fill: {
    flex: 1,
  },
  spacer: {
    height: SPACER,
    justifyContent: 'center',
    alignItems: 'center',
  },
  spacerText: {
    color: '#777',
  },
  gradientView: {
    marginHorizontal: 16,
    marginRight: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  rounded: {
    borderRadius: 24,
    overflow: 'hidden',
    borderWidth: 2,
    borderColor: '#fff',
  },
  listItem: {
    marginVertical: 8,
    borderRadius: 12,
  },
  label: {
    color: '#fff',
    fontWeight: '600',
  },
  referenceStrip: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    right: 0,
    width: 16,
  },
  controls: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 24,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 8,
  },
  button: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#000a',
  },
  buttonActive: {
    backgroundColor: '#2563eb',
  },
  buttonText: {
    color: '#fff',
  },
});
