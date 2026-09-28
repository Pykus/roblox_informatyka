# Roblox reusable sliding-door controller

This repository contains a small, practical Roblox server-side component for button-controlled sliding doors.

## What it does
- discovers every model tagged `InteractiveDoor`;
- validates the expected model structure before attaching handlers;
- opens the door with `TweenService`;
- ignores repeated clicks while a transition is running;
- automatically closes the door after a configurable delay;
- supports multiple independent doors with the same script.

## Required model structure
Each tagged model must contain:
- a `BasePart` named `Door`;
- a `BasePart` named `Button`;
- a `ClickDetector` inside `Button`.

Configure behavior with model attributes:
- `OpenDistance` (number, default `6`);
- `OpenTime` (number, default `0.8`);
- `AutoCloseDelay` (number, default `3`).

The door slides along its local X axis from the position it had when the controller attached.
## Installation
1. Put `DoorController.server.lua` in `ServerScriptService`.
2. Create one or more door models using the structure above.
3. Add the CollectionService tag `InteractiveDoor` to each model.
4. Set optional attributes on the model.
5. Run the place and click the button.

The script is fully server-side, so the authoritative door state is not controlled by the client.

## Example
A model with `OpenDistance = 8`, `OpenTime = 1.0`, and `AutoCloseDelay = 5` opens eight studs, takes one second to move, and closes five seconds later.

## Project layout
`default.project.json` is included for Rojo users, but the Lua file can also be copied directly into Roblox Studio.

This is application code, not lesson material. All names and values are generic and contain no environment-specific data.
