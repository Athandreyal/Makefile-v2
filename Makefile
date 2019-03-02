#simplistic directory path, no leading/training designators, ie, 'src' rather than './src/'
INCLUDES_DIR=includes
INCLUDES_DEPTH=5
SOURCE_DIR=
SOURCE_DEPTH=3

OBJ_DIR=obj
BIN_DIR=bin
DEP_DIR=.dep

$(info $(wildcard src/*))

#	WORKING
#   determination of include chains from given trunk file name
#   complete rule meta programming - generates the rule needed for the program build when called
#   complete support for at least first layer directory structure
#   c/c++ compatibility
#   all source in known directories queried for "int main()", those found appended to PROGRAMS var, all throws foreach prog in programs ONERULE prog to build everything we know of
#   $(MAKECMDGOALS) is matched against located source files, with int main, will throw ONERULE if a match - builds programs found via grep for int main
#   support for CC/CXX/CPP FLAGS where appropriate
#   does not care if source files are scattered across sub directories, so long as all exist as shildren of stated source dir
#   supports lists of direcotirs for src and includes dirs
#   supports multiple coexisting programs
#   inherits .d dependency info pulled form compiler -MM flags
#   
#	TODO
#   test includes stated with relative paths
#   test complex include dirs with relative path includes
#   test gtest build capability
#       - find overlap with main builds to predict gcov expectations
#   valgrind - as simple as a meta-rule to wrap - or can a simple make function $call suffice.
#	- should be able to throw build call as a pre-req by detecting a valgrind call.
#   keep the module lists to help reduce work?
#   replace the $subst functions to something a little stronger match wise, potential to replace in the middle of a name currently.
#	- nearly complete, there is almost no usage of subst now as compared to before
#   meta variable rules - sed should be able to parse the makefile, just need appropriate configuration rules to make the edits.

$(if $(shell builtin command -v bc >/dev/null || echo "Failure"),$(error requisite functionality no present - recursive wildcard function will fail without bc.),)


help:
	$(info *** Configuration Variables ***)
	$(info INCLUDES_DIR 	Supports multiple directores, space separated,)
	$(info .		  do not include trailing slash or preceding ./)
	$(info .		  'includes' instead of './includes/')
	$(info )
	$(info INCLUDES_DEPTH	Recursive depth to search for additional files.)
	$(info .		Must be an integer greater than zero.)
	$(info )
	$(info SOURCE_DIR 	Supports multiple directores, space separated)
	$(info .		Do not include trailing slash or preceding ./)
	$(info .		'src other/src2' instead of './src/ ./other/src2/')
	$(info )
	$(info SOURCE_DEPTH	Recursive depth to search for additional files.)
	$(info .		Must be an integer greater than zero.)
	$(info )
	$(info OBJ_DIR		Target directory for compiled .o files.)
	$(info .		.o files are placed relative to their source.)
	$(info .		  - in the obj dir if specified, beside the source if not)
	$(info )
	$(info BIN_DIR		Target directory for executables.)
	$(info .		If not specified, they will end up next to the source file.)
	$(info )
	$(info DEP_DIR		Target directory for .d dependency tracking files.)
	$(info .		If not specified, they will end up next to the source file.)
	$(info )
	$(info *** Recipes ***)
	$(info Meta Rules	No explicit rules are given for any program or object file.)
	$(info .		.o files use implict pattern matching to build, and the)
	$(info .		given directory paths to find source/includes files.)
	$(info .		'make target' will cause make to check if it is a)
	$(info .		program make found, if so, it parses out the includes and)
	$(info .		attempts to assemble it. Object files are handled via wildcard)
	$(info .)
	$(info .		all, <programName>, and <object>.o are in this category.)
	$(info )
	$(info %.o		All object files are assembled via pattern matching to)
	$(info .		determine if the buid should occur with gcc or g++, by matching)
	$(info .		an associated source extension of .c or .cpp)
	$(info )
	$(info clean		removes .o files for which a *.c or *.cpp can be found.)
	$(info .		removes all executables and dependency files)
	$(info .		removes empty <OBJ/DEP/BIN>_DIR (sub)directories if they exist.)
	$(info )
	$(info cleanAll 	as with clean, but removes ALL .o files, regardless of src files)
	$(info )
	$(info cleanFlags	removes the .PROGRAMSOBJECTSFLAGS.mk file)
	$(info .		this file is used to store the flags for a given target build)
	$(info )
	$(info cleanEverything	calls cleanAll and cleanFlags)
	$(info )
	$(info *** Special Recipes ***)
	$(info <*>flags 	functions that allow editing the .PROGRAMSOBJECTSFILE.mk)
	$(info )
	$(info addFlags 	adds flags to a given target name.  Filters duplicates.)
	$(info .		if .PROGRAMSOBJECTS/FLAGS.mk doesnt exist, it will be created)
	$(info .		if the given target entry doesnt exist, it will be appended)
	$(info .		if the given target entry exists, it will be modified.)
	$(info )
	$(info getFLags 	displays the flags assigned to the given target.)
	$(info .		will indicate undefined if the target has no flags assigned)
	$(info )
	$(info removeFlags	removes flags from a given target name.)
	$(info .		if the last flag is remove,d the entry is emptied entirely.)
	$(info .		does not remove the .ORGRAMSOBJECTSFLAGS.mk file.)
	@echo ""

#sanity check the user input
#constrain SOURCE_ and INCLUDES_ DEPTH to natural numbers
isNotNat=$(if $(filter 0,$1),0,$(subst 9,,$(subst 8,,$(subst 7,,$(subst 6,,$(subst 5,,$(subst 4,,$(subst 3,,$(subst 2,,$(subst 1,,$(subst 0,,$1)))))))))))
$(if $(if $(SOURCE_DEPTH),,-)$(call isNotNat,$(SOURCE_DEPTH)),$(info Caution :: SOURCE_DEPTH=$(SOURCE_DEPTH) is invalid, setting equal to 1)$(eval SOURCE_DEPTH=1))
$(if $(if $(INCLUDES_DEPTH),,-)$(call isNotNat,$(INCLUDES_DEPTH)),$(info Caution :: INCLUDES_DEPTH=$(INCLUDES_DEPTH) is invalid, setting equal to 1)$(eval INCLUDES_DEPTH=1))
$(if $(if $(INCLUDES_DIR),,-)$(filter $(addsuffix /,$(INCLUDES_DIR)),$(wildcard */)),,$(error stated includes directory '$(INCLUDES_DIR)' does not exist))
$(if $(if $(SOURCE_DIR),,-)$(filter $(addsuffix /,$(SOURCE_DIR)),$(wildcard */)),,$(error stated source directory '$(SOURCE_DIR)' does not exist))

-include .PROGRAMSOBJECTSFLAGS.mk

#initial expansion to remain within core makefile - appends trailing slash to DIRs - would like to get this step done in secondary expansion as well, but make is......fussy about when I do this./
INCLUDES_DIR:=$(if $(INCLUDES_DIR),$(addsuffix /,$(INCLUDES_DIR)))
SOURCE_DIR:=$(if $(SOURCE_DIR),$(addsuffix /,$(SOURCE_DIR)))
OBJ_DIR:=$(if $(OBJ_DIR),$(OBJ_DIR)/)
BIN_DIR:=$(if $(BIN_DIR),$(BIN_DIR)/)
DEP_DIR:=$(if $(DEP_DIR),$(DEP_DIR)/)

#secondary expansion of directories, prepends ./, to a secondary variable name as well.
INCLUDES_PATH:=$(if $(INCLUDES_DIR),$(addprefix ./,$(INCLUDES_DIR)))
SOURCE_PATH:=$(if $(SOURCE_DIR),$(addprefix ./,$(SOURCE_DIR)))
OBJ_PATH:=$(if $(OBJ_DIR),./$(OBJ_DIR))
BIN_PATH:=$(if $(BIN_DIR),./$(BIN_DIR))
DEP_PATH:=$(if $(DEP_DIR),./$(DEP_DIR))

define shellMath
$(shell echo "$1" | bc)
endef

#starting dir, pattern, maximum depth, target var
define geFilesAndPaths
$(eval FILES=)
$(eval PATHS=)
$(foreach d,$1,$(call rwild,$d,$2,$3))
$(eval FILES=$(sort $(FILES)))
$(eval PATHS=$(sort $(foreach d,$(FILES),$(dir $d))))
endef

#starting dir, pattern, n iterations remaining
define rwild
 $(foreach d,$(wildcard $1*),
   $(if $(filter-out 0,$(call shellMath,$3-1)),
     $(call rwild,$d/,$2,$(call shellMath,$3-1))
   )
   $(eval FILES=$(FILES) $(filter $(subst *,%,$2),$d))
 )
endef
$(warning last working here)
#$(foreach PATH,$(SOURCE_PATHS),$(eval $(PATH)_FILES:
#
#define updateDir
#   $(eval FILES=$(FILES) $(filter $(subst *,%,$2),$(wildcard $1*))
#   $(
#endef



$(call geFilesAndPaths,$(if $(SOURCE_PATH),$(SOURCE_PATH),./),*.c *.cpp,$(SOURCE_DEPTH))
SOURCE_PATHS:=$(PATHS)
SOURCES:=$(FILES)
$(info sources are $(FILES), and $(SOURCES))
SOURCE_DIRS:=$(if $(filter ./,$(SOURCE_PATHS)),./ $(subst ./,,$(SOURCE_PATHS)),$(subst ./,,$(SOURCE_PATHS)))
$(call geFilesAndPaths,$(if $(INCLUDES_PATH),$(INCLUDES_PATH),./),*.h *.hpp,$(INCLUDES_DEPTH))
INCLUDES_PATHS:=$(PATHS)
INCLUDES_DIRS:=$(if $(filter ./,$(INCLUDES_PATHS)),./ $(subst ./,,$(INCLUDES_PATHS)),$(subst ./,,$(INCLUDES_PATHS)))
DEP_PATHS:=${addprefix $(DEP_PATH),$(SOURCE_PATHS)}

$(info SOURCE_PATHS=$(SOURCE_PATHS))
$(info SOURCE_PATHS has $(words $(subst /,,$(SOURCE_PATHS))) paths)

$(info INCLUDES_PATHS=$(INCLUDES_PATHS))
$(info INCLUDES_PATHS has $(words $(subst /,,$(INCLUDES_PATHS))) paths)

#programs list:
#	use this to mitigate the cost of rescanning the directory to see what programs exist
#	use the source code as dependency
#	use the sourceDirs to trigger an addition via rescan of updated dir

#dir dependencies
#	use this to mitigate the cost of a complete rescan by detecting  what has changed
#	use the dirs as dependencies for each other.


#parse the source dirs, build a dependency tree of directories - adding or removing a file updates a dir's timestamp
#use the directories as rebuild triggers for known source files.


define rwildcard
$(foreach d,$(wildcard $1*),
 $(call rwildcard,$d/,$2)
 $(info $$2=$2)
 $(info $$d=$d)
 $(filter $(subst *,%,$2),$d))
endef


test:
	@echo "test execution completed"


#tells make where to find source files
vpath %.c $(SOURCE_PATHS)
vpath %.cpp $(SOURCE_PATHS)
vpath %.h $(INCLUDES_PATHS)
vpath %.hpp $(INCLUDES_PATHS)
vpath %.d $(DEP_PATHS)

# RULES
# all 			- any variation in capitalisation accepted, builds all detected programs
# $(program) 		- make passes any unknown commands through the programs list, if it matches one, make builds that program
# *.o 			- calling with make obj.o has predictable results, make will try to locate the
# clean			- rm's replacable object files, program executables, and their associated directories if empty
# cleanall		- as with clean, also kills irreplacable object files.
# cleanflags		- kills the .PROGRAMSOBJECTSFLAGS.mk file
# cleaneverything	- calls cleanflags and cleanall.
# addflags		- appends and/or saves flags to an external file for usage in later builds of target
# getflags		- retrieves flags form external file for a given target
# removeflags		- removes flags from an external file for later builds of target

#finds all *.c and *.cpp that contain some variation of int main(), excluding preceding comment --can be fooled by block commenting and preprocessor directives
PROGRAMS=${shell grep -rlP "(?=^(?!//).*$$)(int[ ]*main[ ]*\()" | grep -oP "[/](\K\w)[^.]*" | sort -r| uniq}

#finds all *.c and *.cpp that contain some variation of int main(), excluding preceding comment --can be fooled by block commenting and preprocessor directives
PROGRAMS2=${sort ${foreach d,${if $(SOURCE_PATH),$(SOURCE_PATH),.},${basename ${notdir ${shell find $d -maxdepth $(SOURCE_DEPTH) -name "*.c" -o -name "*.cpp" | xargs grep -lP "(?=^(?!//).*$$)(int[ ]*main[ ]*\()"}}}}}

PROGRAMS3=${sort ${shell echo $(SOURCES) | xargs grep -lP "(?=^(?!//).*$$)(int[ ]*main[ ]*\()"}}  #still have to grep the files - may want to improve upon this
$(info programs  = $(PROGRAMS))
$(info programs2 = $(PROGRAMS2))
$(info $(SOURCES))
$(info programs3 = $(PROGRAMS3))

#should not kill any .o I cannot replace -- ie, I do not have an associated .c or .cpp for it.
clean:
	@rm -f $(if $(BIN_DIR),-r $(BIN_DIR),$(foreach P,$(PROGRAMS),$P))
	$(if $(all),$(call clean_dep_files))
	$(if $(all),@rm -f $(if $(OBJ_DIR),-r $(OBJ_DIR),$(foreach D,$(SOURCE_PATHS),$D*.o)),$(call clean_obj_files))

cleaneverything:cleanEverything
cleanEverything:cleanAll cleanFlags
cleanflags:cleanFlags
cleanFlags:
	@rm -f .PROGRAMSOBJECTSFLAGS.mk
cleanall:all=true
cleanall:cleanAll
cleanAll:all=true
cleanAll:clean

#find .o files, check if I have source files for them, and if so, kill them, then remove any empty obj dirs
define clean_obj_files
$(eval SRC_NAMES=)
$(eval DIRS=$(subst ./,,$(addprefix $(OBJ_PATH),$(SOURCE_PATHS))))
$(eval FILES=$(foreach d,$(DIRS),$(wildcard $d*.o)))
$(foreach f,$(FILES),$(call to_src_name,$(notdir $f))$(eval SRC_NAMES=$(SRC_NAMES) $(SRC_NAME)))
$(eval EXPENDABLE=$(subst .c,.o,$(subst .cpp,.o,$(SRC_NAMES))))
$(shell rm $(addprefix $(OBJ_PATH),$(EXPENDABLE)) 2> /dev/null)
$(foreach d,$(DIRS) $(OBJ_DIR),$(shell rmdir --ignore -p $d 2>/dev/null))
endef

define clean_dep_files
$(eval FILES=$(foreach d,$(DEP_PATHS),$(wildcard $d*.d)))
$(shell rm $(FILES) 2> /dev/null)
$(foreach d,$(DEP_PATHS) $(DEP_DIR),$(shell rmdir --ignore -p $d 2>/dev/null))
endef

#can handle multiple directories, nested source and current dir source, simultaneously.  can also complain if ambiguous results occur - two or more hits for same search.
#stores its result in SRC_NAME, so any calling function can immediately refer to SRC_NAME.

#gets objects for arg1 - expects an extensionless name, will drop any extensions it is given.
define get_objects
$(eval TMP_OBJECTS=)$(eval SRC_NAMES=)$(eval SRC_NAME=)$(eval TMP_INCLUDES=)$(eval TMP_NEW_INCLUDES=)$(eval TMP_CHECKED_INCLUDE=)
$(eval $(call recurse_includes,$(basename $1)))
$(eval TMP_OBJECTS=$(subst .c,.o,$(subst .cpp,.o,$(SRC_NAMES))))
endef

#takes a filename, drops the extension and attempts to wildcard it to .c or .cpp in one of the given/found source directories.  Will terminate compilation if it matches multiple files
#because this uses multiple directories in its query, it can have multiple hits on the same target - MUST make a second pass to strip off the search directories and sort to eliminate duplicates
define to_src_name
$(eval SRC_NAME=$(subst ./,,$(filter-out %~,$(foreach d,$(SOURCE_PATHS),$(wildcard $d$(basename $1).c*)))))
$(if $(filter-out 0 1,$(words $(SRC_NAME))),$(warning ambiguous source naming found: $(SRC_NAME))$(error change the names or constrain the makefile source search depth))
endef

#asks the compiler what the includes are for a given file
define ask_compiler_includes
$(eval TMP_NEW_INCLUDES=$(filter-out %: \,$(shell g++ -MM $(if $(INCLUDES_PATHS),$(addprefix -I,$(INCLUDES_PATHS)) )$1)))
$(eval TMP_NEW_INCLUDES=$(sort $(TMP_INCLUDES) $(TMP_NEW_INCLUDES)))
endef

#recursively chases the includes of files it is given - linear progression.  Equivalent to while(len(list) > 0){ do-NON-recursive-work(list.pop()) }
define recurse_includes
$(eval TMP_CHECKED_INCLUDE=$(sort $1 $(TMP_CHECKED_INCLUDE)))
$(eval TMP_INCLUDES=$(filter-out $1,$(TMP_INCLUDES)))
$(call to_src_name,$1)
$(if $(SRC_NAME),
 $(eval TMP_CHECKED_INCLUDE=$(sort $(SRC_NAME) $(TMP_CHECKED_INCLUDE)))
 $(eval SRC_NAMES=$(sort $(SRC_NAMES) $(SRC_NAME)))
 $(call ask_compiler_includes,$(SRC_NAME))
 $(eval TMP_INCLUDES=$(filter-out $(TMP_CHECKED_INCLUDE),$(sort $(TMP_INCLUDES) $(TMP_NEW_INCLUDES))))
 )
$(if $(TMP_INCLUDES),$(eval $(call recurse_includes,$(firstword $(TMP_INCLUDES)))))
endef


#one rule to build them all!
#cannot be compressed to single line - requires the newlines and tabbing to survive parsing
#if we are here, we needed to figure out the module list
define ONERULE
$1: $(if $(OBJ_PATH),$(addprefix $(OBJ_PATH),$2),$2) | $(if $(BIN_DIR),$(BIN_PATH)$(dir $1),.)
	$$(info |       ======={>  building $1: $2)
	$(if $(findstring .cpp,$(SRC_NAMES)),g++ $(CXXFLAGS),gcc $(CCFLAGS)) $(CPPFLAGS) $($1FLAGS) $(if $(INCLUDES_PATHS),$(addprefix -I,$(INCLUDES_PATHS)) )$$^ -o $(BIN_PATH)$$@
endef

%/:		#generates directories - append / to trigger this rule
	@mkdir -p $@

%.o:$(OBJ_PATH)%.o
$(OBJ_PATH)%.o:%.c %.d | $(@D)/ $(DEP_PATH)$(if $(*D),$(*D),.)/
	$(info dirs are $(@D) $(*D))
	gcc $(CCFLAGS) -MT $@ -MMD -MP -MF $(DEP_PATH)$*.d $(CPPFLAGS) $(if $(INCLUDES_DIR),$(addprefix -I,$(INCLUDES_PATHS)) )-c $< -o $@
	@touch $@
$(OBJ_PATH)%.o:%.cpp %.d | $(OBJ_PATH)
	g++ $(CXXFLAGS) -MT $@ -MMD -MP -MF $(DEP_PATH)$*.d $(CPPFLAGS) $(if $(INCLUDES_DIR),$(addprefix -I,$(INCLUDES_PATHS)) )-c $< -o $@
	@touch $@

#over ride the builtin rule and use .PRECIOUS so make doesn't eliminate the .d files as unecessary intermediate files.
%.d: ;
.PRECIOUS: $(DEP_PATH)%.d


doGetFlags=$(if $($1FLAGS),$(info $1FLAGS=$($1FLAGS)),$(info $1FLAGS is undefined))

define doRemoveFlags
$(if $($1FLAGS),
$(eval STRING1=$1FLAGS=$($1FLAGS))
$(eval STRING2=$1FLAGS=$(filter-out $(flags),$($1FLAGS)))
$(if $(subst $1FLAGS=,,$(STRING2)),,$(eval STRING2=))
$(shell sed -i "s/$(STRING1)/$(STRING2)/g" .PROGRAMSOBJECTSFLAGS.mk)
)
endef

define doAddFlags
$(if $($1FLAGS)
,
 $(eval STRING1=$1FLAGS=$($1FLAGS))
 $(eval STRING2=$1FLAGS=$(sort $(flags) $($1FLAGS)))
 $(shell sed -i "s/$(STRING1)/$(STRING2)/g" .PROGRAMSOBJECTSFLAGS.mk)
,
 $(file >> .PROGRAMSOBJECTSFLAGS.mk,$1FLAGS=$(sort $(subst ~,-,$(flags))))
)
endef

-include $(wildcard $(DEP_PATH)*.d)


to_lowercase			=$(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))


ifneq ($(filter $(call to_lowercase,$(MAKECMDGOALS)),getflag getflags addflag addflags removeflag removeflags),)
ifneq ($(filter $(call to_lowercase,$(MAKECMDGOALS)),addflag addflags removeflag removeflags),)
$(if $(flags),,$(error flags variable undefined. Use with 'make <addflags/removeflags> <target> flags="<-flag1 -flag2...-flagN>"'))
endif
$(eval FIRST=$(firstword $(MAKECMDGOALS)))
$(eval SECOND=$(firstword $(filter-out $(FIRST),$(MAKECMDGOALS))))
$(eval FIRST=$(call to_lowercase,$(FIRST)))
ifneq ($(filter $(FIRST),addflag addflags),)
$(call doAddFlags,$(SECOND))
$(eval -include .PROGRAMSOBJECTSFLAGS.mk)
$(call doGetFlags,$(SECOND))
$(eval MESSAGE=flags added)
else ifneq ($(filter $(FIRST), getflag getflags),)
$(call doGetFlags,$(SECOND))
$(eval MESSAGE=flags queried)
else ifneq ($(filter $(FIRST), removeflag removeflags),)
$(call doRemoveFlags,$(SECOND))
$(eval -include .PROGRAMSOBJECTSFLAGS.mk)
$(call doGetFlags,$(SECOND))
$(eval MESSAGE=flags removed)
endif
$(error $(MESSAGE), forcefully terminating make now  --  this is not an error  --)
endif

#    $(foreach P,$(filter $(MAKECMDGOALS),$(PROGRAMS)),$(if $($POBJS),$(eval $(call ONERULE,$P,$($POBJS))),$(call get_objects,$P)$(eval $(call ONERULE,$P,$(TMP_OBJECTS)))))
#    $(foreach P,$(PROGRAMS),$(if $($POBJS),$(info $POBJS=$($POBJS))$(eval $(call ONERULE,$P,$($POBJS))),$(info $POBJS undef, getOBJS)$(call get_objects,$P)$(eval $(call ONERULE,$P,$(TMP_OBJECTS)))))

ifneq ($(filter $(MAKECMDGOALS),$(PROGRAMS)),)
    $(info making $(filter $(MAKECMDGOALS),$(PROGRAMS)))
    $(foreach P,$(filter $(MAKECMDGOALS),$(PROGRAMS)),$(call get_objects,$P)$(eval $(call ONERULE,$P,$(TMP_OBJECTS))))
else ifneq ($(filter $(call to_lowercase,$(MAKECMDGOALS)),all),)
    $(info making all)
    $(foreach P,$(PROGRAMS),$(call get_objects,$P)$(eval $(call ONERULE,$P,$(TMP_OBJECTS))))
    all: $(PROGRAMS)#intercept the all calls, and give them something to do so make shuts up about them
	@echo -ne ""
endif
