using Documenter
ext = Base.get_extension(MakieMaestro, :DocumenterExt)
@assert !isnothing(ext)
@test ext.MakieBlockOptions(name="name1") == parse(ext.MakieBlockOptions, " name1")
@test ext.MakieBlockOptions(name="name2", basename="basename1") == parse(ext.MakieBlockOptions, " name2; basename=\"basename1\"")
@test ext.MakieBlockOptions(name="name2", caption="caption1") == parse(ext.MakieBlockOptions, " name2; caption=\"caption1\"")
@test ext.MakieBlockOptions(name="name2", basename="basename1") == parse(ext.MakieBlockOptions, " name2; formats = [:png, :pdf] , basename=\"basename1\"")
@test ext.MakieBlockOptions(name="name2", basename="basename1", caption="caption1") == parse(ext.MakieBlockOptions, " name2; caption = \"caption1\" , basename=\"basename1\"")
