# MakieMaestro Test

```@example A
A = sin.(0:0.1:pi)
```

```@makie A
lines(A)
```

```@makie B; basename="cos"
lines(cos.(0:0.1:pi))
```

```@makie C; formats = [:png, :pdf], basename="formats"
lines(cos.(0:0.1:pi))
```

```@makie D; theme=[:orange_title, :rotate_labels]
f,ax,_ = lines(sin.(0:0.1:pi))
ax.title = L"\sin"
f
```

```@makie D; size=25u"cm"
lines(sin.(0:0.1:pi))
```

```@makie; basename="noname"
lines(exp.(-3:0.1:3))
```
