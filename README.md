# Dangerous Asteroids Radar Tracking (D.A.R.T.)

An optimized asteroid defense


## Features
Are you also sick of wasting ammunition on asteroids that fly safely past your platforms? 

Then D.A.R.T. might be the solution for you. It continuously monitors the space around your platforms, controls the 
connected ammo turrets, and prioritizes the approaching asteroids. Those that are heading directly toward your platforms
and are likely to collide with them are attacked, while the others are ignored, saving you tons of ammunition.

## Components
D.A.R.T. consist of two special devices. The central fire control computer (FCC) and a specialized variant of radar -
miniaturized with reduced power consumption and only usable on platforms. To use them, you have to research the D.A.R.T. 
technology.

![D.A.R.T. technology](https://github.com/xyzzycgn/dart/blob/main/doc/dart-technology.png?raw=true)

## Usage
To protect a platform with D.A.R.T., you have to build a FCC and at least one dart-radar (exact number depends on size and 
shape of your platform to cover it complete) additionally to your turrets. Communication between FCC and dart-radars uses a top secret military 
technique, called Light Ubiquity Architecture 😉 and needs no further interaction by you. As soon as FCC and dart-radars 
are placed on a platform the connection between them will be established. 

To control ammo turrets with D.A.R.T., you have to connect them with red or green wire with the FCC.

![D.A.R.T. on a platform](https://github.com/xyzzycgn/dart/blob/main/doc/dart-on-platform.png?raw=true)

## Configuration
Configuration can be done by simply opening the FCC 

![configure FCC](https://github.com/xyzzycgn/dart/blob/main/doc/dart-configure-main.png?raw=true)

All (= all on platform) dart-radars and ammo-turrets are accessible through this. Unconnected ammo-turrets or turrets 
with ambiguous circuit network conditions will be shown with according warnings.


To use D.A.R.T., it must be configured (per platform). This has to be done in these steps (not necessarily in this order)

- set the size of the defended area (recommended). The defended area consist of (overlapping) circles with the dart-radars as center 

![configure radar](https://github.com/xyzzycgn/dart/blob/main/doc/dart-configure-main-radar.png?raw=true)

- set the detection range too (optional)

- set the circuit network conditions in all connected ammo turrets by switching to the "turrets"-tab 

![show turrets](https://github.com/xyzzycgn/dart/blob/main/doc/dart-configure-main-turrets.png?raw=true)

  and clicking on the turret to be configured (**mandatory**)

![configure turret](https://github.com/xyzzycgn/dart/blob/main/doc/gun-turret.png?raw=true|height=300)

**Hint**
D.A.R.T. controls a turret by setting its circuit network condition to 0 resp. 1.

## Compatibility
This mod is compatible to vanilla game (= space age) and other mods introducing new turrets derived from 
ammo-turret prototype and/or new ammunition for these turrets.

**IMPORTANT**: For working correctly with D.A.R.T., mods introducing new turrets need connectivity to the circuit network
(i.e. the turrets must be connectible with red or green wire). This can be achieved by the other mod itself or require 
some additional (specifically adapted for each mod) support by this mod (introduced in v 1.0.15).

Currently these mods are known to work fine with it:
- [Cupric Asteroids](https://mods.factorio.com/mod/cupric-asteroids) [^1] 
- [Modular Turrets](https://mods.factorio.com/mod/scattergun_turret) [^1]
- [Cannon Turret](https://mods.factorio.com/mod/vtk-cannon-turret) [^2]
- [Rampant Arsenal (Fork)](https://mods.factorio.com/mod/RampantArsenalFork) [^2]

If you have experience with other mods working too, please let me know. If you're missing another mod without an own 
connectivity to the circuit network and want to use it together with D.A.R.T., let me know too - I will have a look at it.

## Supported languages in this version:
  - čeština (cs)
  - deutsch (de)
  - english (en)
  - español (es-ES)
  - suomi (fi)
  - français (fr)
  - italiano (it)
  - 日本語 (ja)
  - 한국인 (ko)
  - nederlands (nl)
  - norsk (no)
  - polski (pl)
  - português (pt-BR)
  - русский (ru)
  - senska (sv-SE)
  - українська (uk-UA)    
  - 中国人 (zh-CN)
  - 中國人 (zh-TW)

# Have fun

----
[^1]: runs out of the box

[^2]: needs support by D.A.R.T. for adding the connectivity to the circuit network
