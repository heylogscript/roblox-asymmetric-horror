# UI Changes Made to StaminaSprintUI.local.luau

## Summary
Replaced the rectangular health/stamina bars with circular ability icons featuring:
- Dark horror aesthetic (inspired by Dead by Daylight)
- Hand-drawn white artwork style (white outlines on dark backgrounds)
- Circular fill mechanics that grow from center
- Subtle animations and feedback

## Files Modified
- `StaminaSprintUI.local.luau` - Complete replacement with circular icon system

## Key Features

### Visual Design
- Two circular icons (health & stamina) positioned at bottom-left
- Dark background circles: RGB(10, 10, 15) - very dark gray-blue
- White 2px stroke/border creating hand-drawn outline effect
- Center symbols: ♥ for health, ⚡ for stamina (easily replaceable with artwork)
- Fill colors: Health = Reddish (RGB(220, 40, 60)), Stamina = Bluish (RGB(80, 180, 255))

### Functionality
- Circular fills grow from center outward as resources increase
- Health icon reflects current health percentage
- Stamina icon reflects current stamina percentage
- Low stamina warning (<20%): Icon pulses and text turns reddish
- Sprint activation: Icons pulse when sprinting
- Maintains all existing stamina drain, regeneration, and input systems

### Technical Implementation
- Uses `UICorner` with `CornerRadius = UDim.new(0.5, 0)` for perfect circles
- Fill circles animate via size changes from center anchor point
- Subtle heartbeat-driven pulse animations for feedback
- Position: 24px from left, 100px from bottom of screen
- Icon size: 50x50 pixels each

## Integration Notes
- Fully compatible with existing `PlayerStatsSystem.legacy.luau`
- Uses same `SetSprinting` RemoteEvent for input
- Reads stamina from player attributes (`Stamina`, `MaxStamina`)
- Reads health directly from Humanoid.Health/MaxHealth
- No changes needed to server-side or configuration files

## Customization Options
To modify appearance:
1. **Colors**: Change `Color3.fromRGB()` values in `createAbilityIcon()`
2. **Sizes**: Adjust iconFrame size and position values
3. **Positions**: Modify `iconContainer.Position`
4. **Artwork**: Replace `iconLabel.Text` with ImageLabel containing hand-drawn art
5. **Effects**: Adjust pulse frequency/intensity in Heartbeat connection

## Future Enhancements
- Add actual hand-drawn artwork images instead of text symbols
- Add glow effects to icons when full/active
- Add particle effects on stamina depletion
- Add sound effects for low stamina/sprint start/stop
- Add radial cooldown overlays for abilities