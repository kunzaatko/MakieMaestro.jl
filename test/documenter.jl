using Documenter
ext = Base.get_extension(MakieMaestro, :DocumenterExt)
@assert !isnothing(ext)
@test ext.MakieBlockOptions(name="name1") == parse(ext.MakieBlockOptions, " name1")
@test ext.MakieBlockOptions(name="name2", basename="basename1") == parse(ext.MakieBlockOptions, " name2; basename=\"basename1\"")
@test ext.MakieBlockOptions(name="name2", caption="caption1") == parse(ext.MakieBlockOptions, " name2; caption=\"caption1\"")
@test ext.MakieBlockOptions(name="name2", basename="basename1") == parse(ext.MakieBlockOptions, " name2; formats = [:png, :pdf] , basename=\"basename1\"")
@test ext.MakieBlockOptions(name="name2", basename="basename1", caption="caption1") == parse(ext.MakieBlockOptions, " name2; caption = \"caption1\" , basename=\"basename1\"")

# TODO: Add tests for the running of Documenter. Do the plots really run? There are some problems in other packages that
# use this... <31-07-25> 
# TODO: Return helpful errors for errors that happen in the blocks instead of just throwing when the plotting does not
# work <12-08-25> 
