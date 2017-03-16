#%Module 1.0 -*- tcl -*-

proc getDirName { appsroot appname } {
    set dirlist [glob -nocomplain -directory $appsroot -tails *]
    #set match 0
    #set res [regexp -nocase $appname $dirlist match]
    #return $match
    set res [lsearch -inline -nocase [split $dirlist] $appname]
    return $res
}
#proc setCommonVariables { } {
    set ::module_name [lrange [split [ module-info name ] / ] 0 0 ]
    set ::module_name_uc [string toupper $::module_name]
    set ::module_name_lc [string tolower $::module_name]
    set ::version [ file tail [ module-info name ] ]
    set ::distro $::env(KAUST_DISTRO)
    set ::distro_fb el6
    set ::m_arch $::env(KAUST_ARCH)
    set curpath [file dirname $::ModulesCurrentModulefile]
    #set ::module_extra_dir "[file dirname $::ModulesCurrentModulefile]/../../applications-extra"
    set ::module_extra_dir [regsub {/(applications|compilers|libs)/} $curpath {/\1-extra/} ]
    set ::dir_name $::module_name
#}


# Log what's happening
exec $env(KAUST_MODULES_ROOT)/common/log.sh --mode [module-info mode] \
     --name [module-info name] --path $ModulesCurrentModulefile &


proc checkLicense {} {
    global module_extra_dir

    if [file exists "$module_extra_dir/.nolicense"] {
       puts stderr "\033\[7;31;31m"
       puts stderr "License has expired!"
       puts stderr ""
       puts stderr "* For more information, please contact IT Software Solutions Office:"
       puts stderr ""
       puts stderr "\tsso@kaust.edu.sa"
       puts stderr "\033\[m"
       exit 1
    }
}

proc SetAppDir { suffix_dir { app_dir_env 0 } } {

    #KAUST APPNAME
    regsub -all {[\-]} ${::module_name_uc} "_" KAUST_APPNAME
    setenv KAUST_APPNAME ${KAUST_APPNAME}

    if { $app_dir_env == 0 } {
        #set app_dir_env ${::module_name_uc}
        #regsub -all {[\-]} $app_dir_env "_" tmp_env
        set app_dir_env ${KAUST_APPNAME}_ROOT
    }

         # app_root
    if { [info exists ::env(KAUST_APPS_ROOT)] } {
       set ::apps_root $::env(KAUST_APPS_ROOT)
    } else {
       set ::apps_root /opt/share
    }

    set ::dir_name [getDirName $::apps_root $::dir_name]

    # app_dir
    if { [info exists ::env(${app_dir_env})] } {
       set ::app_dir $::env(${app_dir_env})
    } else {
       set ::app_dir $::apps_root/$::dir_name/$suffix_dir

       #Do we need to fallback
       if { [file exists $::app_dir] == 0 } {
            set ::app_dir [string map "/$::distro /$::distro_fb" $::app_dir]
        }
    }
    # out of the if-stm, to be shown on "module show"
    setenv ${app_dir_env} $::app_dir
}



proc GeneralModulesHelp {} {
    puts stderr "\tThis module loads $::module_name version $::version\n"
}


proc SetWhatis {} {
    global module_extra_dir
    global desc_file

    set desc_file [join [read [ open "$module_extra_dir/.desc" ] ] ]
    module-whatis   "$desc_file"
}



proc WS_CURL_LOG {} {
    set hostname [exec hostname]
    set hn [string range $hostname 0 1]

    if {[string equal $hn kw]} {

        set module "$::module_name-$::version"
        set hostname [exec hostname]
        set user [exec whoami]

        #Needs a machine that all workstations can connect to
        catch {exec bash -c "curl --connect-timeout 1 http://10.126.106.39:8887/wslog/$module/$hostname/$user/ 2>/dev/null "}
        catch {exec bash -c "curl --connect-timeout 1 http://10.126.106.12:8887/wslog/$module/$hostname/$user/ 2>/dev/null "}
        #puts stderr "loading $module"
    }
}


proc WriteLog {} {
    set hostname [exec hostname]
    set hn [string range $hostname 0 1]

    if {[string equal $hn kw]} {

        set hostname [exec hostname]
        set logdir /var/log/rc
        set user [exec whoami]


        set logfile "/var/log/rc/module_log_${hostname}_${user}"

#   set logfile "/var/log/rc/rcapps_modules_load.log"
#   set logfile "/tmp/rcapps_modules_load.log"


    if {[file exists $logdir]} {
        set date [exec date]
        set data "$date  $hostname  $user  $::module_name $::version"

        set fileId [open $logfile "a"]
        puts $fileId $data
        close $fileId

#        puts stderr "$logfile => $data"
    }
  }
}


proc ReportModuleUsage {} {
    global loading
    global unloading

    set loading [module-info mode load]
    set unloading [module-info mode remove]

    switch [module-info mode] {
        load {
            puts stderr "Loading module $::module_name version $::version"
        }
        remove {
            puts stderr "Unloading module $::module_name version $::version"
        }
    }

    WS_CURL_LOG
}

proc ReportIntelVersion {} {
    global current_version
    if {[catch {set current_version [exec $::module_name --version | head -n1 | awk "{ print \$3 }" ]} e]} {
        set current_version none
    }

    puts stderr "Current $::module_name version: $current_version"
}

#proc GeneralAppSetupNoarch { } {
#    proc ModulesHelp { } {
#        GeneralModulesHelp
#    }

#    SetWhatis
#    ReportModuleUsage

#    conflict $::module_name
#}



proc GeneralAppSetup { { suffix_dir 0 } { app_dir_env 0 }   } {
    proc ModulesHelp { } {
        GeneralModulesHelp
    }


    # Set defualt suffix_dir to vVersion.app e.g: v8.8.app
    if { $suffix_dir ==0} { set suffix_dir v${::version}.app }

    SetAppDir $suffix_dir $app_dir_env

    SetWhatis
    ReportModuleUsage

    conflict $::module_name
}

proc GeneralCompilerSetup { { suffix_dir 0 } { app_dir_env 0 }   } {
    if { $suffix_dir ==0} { set suffix_dir ${::version}/${::distro} }
    GeneralAppSetup $suffix_dir $app_dir_env
}

proc GeneralLibSetup  { { suffix_dir 0 } { app_dir_env 0 }   } {
    if { $suffix_dir ==0} { set suffix_dir ${::version}/${::distro}/${::m_arch} }
    GeneralAppSetup $suffix_dir $app_dir_env
}

proc AddDeps { csv_list } {
    # Process dependancies
    set modules_to_load [split $csv_list ","]
    foreach line $modules_to_load {
        if {$line != ""} {
            set line [string trim $line]
            if ![is-loaded $line] {
                module add $line
            }
        }
    }
}

checkLicense
