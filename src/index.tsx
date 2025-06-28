/* eslint-disable no-undef */
import type { Frame } from 'react-native-vision-camera';
import { VisionCameraProxy } from "react-native-vision-camera";
import { useMemo } from "react";

type BoundingFrame = {
  x: number;
  y: number;
  width: number;
  height: number;
  boundingCenterX: number;
  boundingCenterY: number;
};
type Point = { x: number; y: number };

type TextElement = {
  text: string;
  frame: BoundingFrame;
  cornerPoints: Point[];
};

type TextLine = {
  text: string;
  elements: TextElement[];
  frame: BoundingFrame;
  recognizedLanguages: string[];
  cornerPoints: Point[];
};

type TextBlock = {
  text: string;
  lines: TextLine[];
  frame: BoundingFrame;
  recognizedLanguages: string[];
  cornerPoints: Point[];
};

type Text = {
  text: string;
  blocks: TextBlock[];
};

export type OCRFrame = {
  result: Text;
};

type OCRPlugin = {
  scanOCR: ( frame: Frame ) => OCRFrame
}

/**
 * Scans OCR.
 */

function createOcrPlugin(): OCRPlugin {
  const plugin = VisionCameraProxy.initFrameProcessorPlugin( 'scanOCR', {} )

  if ( !plugin ) {
    throw new Error( 'Failed to load Frame Processor Plugin "scanOCR"!' )
  }

  return {
    scanOCR: (
      frame: Frame
    ): OCRFrame => {
      'worklet'
      // @ts-ignore
      return plugin.call( frame ) as OCRFrame
    }
  }
}

export function useOcrPlugin(): OCRPlugin {
  return useMemo( () => (
    createOcrPlugin()
  ), [] )
}
