#%Module 1.0 -*- tcl -*-

proc GeneralModulesHelp {} {
    global name
    global version
    puts stderr "\tThis module loads $name version $version\n"
}

proc SetAppDir {} {
    global app_dir
    global dir_name
    global version
    
   #TODO need to think about this more to make it general

}

proc SetWhatis {} {
    global module_extra_dir
    global desc_file
    global name

    set desc_file [join [read [ open "$module_extra_dir/$name/.desc" ] ] ]
    module-whatis   "$desc_file"
}

proc ReportModuleUsage {} {
    global name
    global version
    global loading
    global unloading

    set loading [module-info mode load]
    set unloading [module-info mode remove]

    switch [module-info mode] {
        load {
            puts stderr "Loading module $name version $version"
        }
        remove {
            puts stderr "Unloading module $name version $version"
        }
    }
}

proc ReportIntelVersion {} {
    global name 
    global current_version
    if {[catch {set current_version [exec $name --version | head -n1 | awk "{ print \$3 }" ]} e]} {
        set current_version none  
    } 

    puts stderr "Current $name version: $current_version"
}

proc GeneralAppSetup {} {
    proc ModulesHelp { } {
        GeneralModulesHelp
    }
   
#    SetAppDir
    SetWhatis
    ReportModuleUsage

#   TODO setenv PACKAGE_ROOT environment variable, e.g., MATLAB_ROOT, BLAS_ROOT, etc

}
