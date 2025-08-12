# MakieMaestro Test

```@example A
A = sin.(0:0.1:pi)
```

```@makie A
f,_,_ = lines(A)
f
```

```@makie B; basename="cos"
f,_,_ = lines(cos.(0:0.1:pi))
f
```

```@makie C; formats = [:png, :pdf], basename="formats"
f,_,_ = lines(cos.(0:0.1:pi))
f
```
