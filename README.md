# Ground-Truth-Generator
Matlab script to generate a 2D plot of the sdf world file used by Gazebo.

Notes:

    1. It can only plot models of type box and cylinder (script looks for these tags only).
    2. Its measurements assume that its model is of size 1 on x, y, and z.
    3. It uses the scale tag to get the x, y, and z dimensions, so that xDim = xScale, based on note 2 assumption. Same thing applies for y.
    4. The png it generates is of 2400 DPI, so it takes a while to generate it.
