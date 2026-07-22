// Package config reads the plugin's opt-in settings from
// $HERDR_PLUGIN_CONFIG_DIR/config.toml: popup scoping mode and float size.
package config

import (
	"os"
	"path/filepath"
	"regexp"

	"github.com/BurntSushi/toml"
)

const (
	configDirEnvVar = "HERDR_PLUGIN_CONFIG_DIR"
	defaultScope    = "global"
	defaultWidth    = "80%"
	defaultHeight   = "80%"
	defaultShell    = "fish"
)

// Config is the subset of config.toml the plugin reads.
type Config struct {
	Scope     string
	Shell     string
	Width     string
	Height    string
	PopupSize map[string]popupDims
}

type popupDims struct {
	Width  string `toml:"width"`
	Height string `toml:"height"`
}

// Load reads scope and size settings from $HERDR_PLUGIN_CONFIG_DIR/config.toml.
func Load() Config {
	def := Config{
		Scope:  defaultScope,
		Shell:  defaultShell,
		Width:  defaultWidth,
		Height: defaultHeight,
	}

	dir := os.Getenv(configDirEnvVar)
	if dir == "" {
		return def
	}

	var parsed struct {
		Scope     string               `toml:"scope"`
		Shell     string               `toml:"shell"`
		Width     string               `toml:"width"`
		Height    string               `toml:"height"`
		PopupSize map[string]popupDims `toml:"popup_size"`
	}
	path := filepath.Clean(filepath.Join(dir, "config.toml"))
	if _, err := toml.DecodeFile(path, &parsed); err != nil {
		return def
	}

	scope := parsed.Scope
	if scope == "" {
		scope = defaultScope
	}
	shell := parsed.Shell
	if shell == "" {
		shell = defaultShell
	}
	width := parsed.Width
	if width == "" {
		width = defaultWidth
	}
	height := parsed.Height
	if height == "" {
		height = defaultHeight
	}
	return Config{
		Scope:     scope,
		Shell:     shell,
		Width:     sanitizeSize(width),
		Height:    sanitizeSize(height),
		PopupSize: parsed.PopupSize,
	}
}

// SizeFor returns width/height for an entrypoint, falling back to global defaults.
func (c Config) SizeFor(entrypoint string) (width, height string) {
	if dims, ok := c.PopupSize[entrypoint]; ok {
		w := sanitizeSize(dims.Width)
		h := sanitizeSize(dims.Height)
		if w == "" {
			w = c.Width
		}
		if h == "" {
			h = c.Height
		}
		return w, h
	}
	return c.Width, c.Height
}

var sizePattern = regexp.MustCompile(`^(100|[1-9][0-9]?)%$|^([1-9][0-9]{0,4})$`)

func sanitizeSize(raw string) string {
	if raw == "" {
		return ""
	}
	if sizePattern.MatchString(raw) {
		return raw
	}
	return ""
}
