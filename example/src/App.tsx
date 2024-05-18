import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import {
  type AudioSyncResult,
  calculateSyncOffset,
} from 'react-native-audio-sync';

let RNFS = require('react-native-fs');

export default function App() {
  const [resultOne, setResultOne] = React.useState<number | undefined>();
  const [resultTwo, setResultTwo] = React.useState<number | undefined>();
  const [resultThree, setResultThree] = React.useState<number | undefined>();
  const [resultFour, setResultFour] = React.useState<number | undefined>();
  const [resultFive, setResultFive] = React.useState<number | undefined>();

  React.useEffect(() => {
    calculateSyncOffset(
      `${RNFS.MainBundlePath}/audioFile1.wav`,
      `${RNFS.MainBundlePath}/audioFile2.wav`
    ).then(({ syncOffset }: AudioSyncResult) => {
      setResultOne(syncOffset);
    });
    calculateSyncOffset(
      `${RNFS.MainBundlePath}/audioFile1.wav`,
      `${RNFS.MainBundlePath}/audioFile3.wav`
    ).then(({ syncOffset }: AudioSyncResult) => {
      setResultTwo(syncOffset);
    });
    calculateSyncOffset(
      `${RNFS.MainBundlePath}/audioFile1.wav`,
      `${RNFS.MainBundlePath}/audioFile4.wav`
    ).then(({ syncOffset }: AudioSyncResult) => {
      setResultThree(syncOffset);
    });
    calculateSyncOffset(
      `${RNFS.MainBundlePath}/audioFile1.wav`,
      `${RNFS.MainBundlePath}/audioFile5.wav`
    ).then(({ syncOffset }: AudioSyncResult) => {
      setResultFour(syncOffset);
    });
    calculateSyncOffset(
      `${RNFS.MainBundlePath}/audioFile4.wav`,
      `${RNFS.MainBundlePath}/audioFile3.wav`
    ).then(({ syncOffset }: AudioSyncResult) => {
      setResultFive(syncOffset);
    });
  }, []);

  return (
    <View style={styles.container}>
      <Text style={[styles.textCenter, styles.textHeader]}>AudioSync</Text>
      <Text style={[styles.textCenter, styles.textMargin]}>
        <Text style={styles.textItalic}>audioFile1</Text> lags behind{' '}
        <Text style={styles.textItalic}>audioFile2</Text> by
      </Text>
      <Text
        style={[
          styles.textCenter,
          styles.textMargin,
          styles.textHighlight,
          styles.textBold,
        ]}
      >
        {resultOne}s
      </Text>
      <Text style={[styles.textCenter, styles.textMargin]}>
        <Text style={styles.textItalic}>audioFile1</Text> lags behind{' '}
        <Text style={styles.textItalic}>audioFile3</Text> by
      </Text>
      <Text
        style={[
          styles.textCenter,
          styles.textMargin,
          styles.textHighlight,
          styles.textBold,
        ]}
      >
        {resultTwo}s
      </Text>
      <Text style={[styles.textCenter, styles.textMargin]}>
        <Text style={styles.textItalic}>audioFile1</Text> lags behind{' '}
        <Text style={styles.textItalic}>audioFile4</Text> by
      </Text>
      <Text
        style={[
          styles.textCenter,
          styles.textMargin,
          styles.textHighlight,
          styles.textBold,
        ]}
      >
        {resultThree}s
      </Text>
      <Text style={[styles.textCenter, styles.textMargin]}>
        <Text style={styles.textItalic}>audioFile1</Text> lags behind{' '}
        <Text style={styles.textItalic}>audioFile5</Text> by
      </Text>
      <Text
        style={[
          styles.textCenter,
          styles.textMargin,
          styles.textHighlight,
          styles.textBold,
        ]}
      >
        {resultFour}s
      </Text>
      <Text style={[styles.textCenter, styles.textMargin]}>
        <Text style={styles.textItalic}>audioFile4</Text> is{' '}
        <Text style={[styles.textBold, styles.textItalic]}>{resultFive}s</Text>{' '}
        ahead of <Text style={styles.textItalic}>audioFile3</Text>
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'white',
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 50,
  },
  textCenter: {
    textAlign: 'center',
  },
  textBold: {
    fontWeight: 'bold',
  },
  textItalic: {
    fontStyle: 'italic',
  },
  textHeader: {
    fontSize: 36,
  },
  textMargin: {
    marginTop: 10,
  },
  textHighlight: {
    fontSize: 24,
  },
});
