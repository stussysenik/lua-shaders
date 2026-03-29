# Chapter 1: Coordinates & UV Space

## The Problem
Every pixel on screen has a position, but raw pixel coordinates are
resolution-dependent. A shader that works at 800x600 breaks at 1080x1920.
How do we create a universal coordinate system?

## The Pattern
**Space Transformation**: normalize, center, correct, and repeat coordinates
before computing any effect. Change the space, not the drawing.

## Prior Knowledge
None -- this is the starting point.

## Koans
1. **The Canvas is a Map** -- normalize pixel positions to 0->1 (UV)
2. **The Stretch Problem** -- correct for non-square screens (aspect ratio)
3. **Moving the Origin** -- center the coordinate system for radial math
4. **Zooming In** -- scale and repeat via fract() (domain repetition)

## GPU Scale
Your screen has ~2 million pixels. At 60fps, the GPU evaluates your
effect() function 124 million times per second. Each koan in this
chapter adds ONE operation to that function. The GPU doesn't care.
