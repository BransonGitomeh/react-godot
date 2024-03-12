shader_type canvas_item;

void fragment() {
    // Retrieve the current color of the pixel
    vec4 color = texture(TEXTURE, UV);

    // Adjust the alpha value to make the element transparent
    color.a *= 0.2; // Adjust the transparency level as needed (0.0 to 1.0)

    // Output the modified color
    COLOR = color;
}
