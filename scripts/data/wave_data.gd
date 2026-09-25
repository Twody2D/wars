class_name WaveData
extends Resource
## A bot wave: starts at `start_sec` of the battle, entries spawn in parallel.

@export var start_sec: float = 0.0
@export var entries: Array[WaveEntry] = []
