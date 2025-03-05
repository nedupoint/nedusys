# nedusys
A tool for reproducible arch linux systems

# Configuring

Read https://github.com/nedupoint/nedusys/wiki

# Compiling

## Step 1.
### To compile this project you need the most latest version of zig currently: 0.14.0-dev.3367+1cc388d52

### To obtain it on arch:
```bash
# Yay
yay -S zig-nightly-bin
```
```bash
# Paru
paru -S zig-nightly-bin
```

## Step 2.

```bash
# clone the repo
git clone https://github.com/nedupoint/nedusys.git
# go into the repo
cd nedusys
# compile
zig build -Doptimize=ReleaseFast
```
