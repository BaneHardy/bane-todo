package require sqlite3;

namespace eval ::bane_todo {
    variable ns [namespace current]

    # Config start
    #--------------------
    # Absolute path to the database file
    set database "/home/bane/eggdrop/scripts/bane-todo.db"
    #--------------------
    # Commands only work when invoked from these channels. Separate them by spaces.
    set channels "#bane-todo1 #bane-todo2"
    #--------------------
    # Trigger commands
    set trigger_todo "!todo"
    #--------------------
    # Config end

    # Binds start
    #--------------------
    bind pub -|- $trigger_todo ${ns}::main
    #--------------------
    # Binds end

    proc checkchannel {chan} {
        variable channels
        if {[lsearch [split [string tolower $channels]] [string tolower $chan]] == -1} {
            putquick "PRIVMSG $chan :Error: Invalid channel."
            return -code return
        }
    }

    proc main {nick host hand chan text} {
        variable ns
        variable trigger_todo
        ${ns}::checkchannel $chan
        set argv [split $text]
        set argc [llength $argv]
        if {$argc == 0} {
            ${ns}::show $chan "0"
        } elseif {$argc == 1} {
            set command [lindex $argv 0]
            if {[string equal -nocase $command "fixed"]} {
                ${ns}::show $chan "1"
            } elseif {[string equal -nocase $command "help"]} {
                ${ns}::help $chan
            } else {
                putquick "PRIVMSG $chan :Error: Invalid command <$command>. Help: $trigger_todo help"
                return
            }
        } elseif {$argc > 1} {
            set command [lindex $argv 0]
            set parameters [join [lrange $argv 1 end]]
            set id [lindex $argv 1]
            set modtext [join [lrange $argv 2 end]]
            if {[string equal -nocase $command "add"] && ![string equal $parameters ""]} {
                ${ns}::add $nick $chan $parameters
            } elseif {[string equal -nocase $command "del"] && ![string equal $parameters ""]} {
                ${ns}::del $chan $parameters
            } elseif {[string equal -nocase $command "fix"] && ![string equal $parameters ""]} {
                ${ns}::fix $chan $parameters
            } elseif {[string equal -nocase $command "mod"] && [string is integer $id] && ![string equal $modtext ""]} {
                ${ns}::edit $nick $chan $id $modtext
            } else {
                putquick "PRIVMSG $chan :Error: Invalid command <$command> or not enough arguments given. Help: $trigger_todo help"
                return
            }
        }
    }

    proc add {nick chan text} {
        variable database
        sqlite3 todo $database
        if {[todo exists {SELECT timestamp FROM todo WHERE todotext=$text}]} {
            putquick "PRIVMSG $chan :Error: This todo already exists in the database."
        } else {
            set timestamp [clock seconds]
            todo eval {INSERT INTO todo VALUES($text, $timestamp, $nick, "0")}
            putquick "PRIVMSG $chan :todo added to database: $text"
        }
        todo close
        return -code return
    }

    proc del {chan text} {
        variable database
        set argv [split $text]
        sqlite3 todo $database
        foreach id $argv {
            if {![string is integer $id]} {
                putquick "PRIVMSG $chan :Error: $id is not a valid number."
            } else {
                if {![todo exists {SELECT timestamp FROM todo WHERE rowid=$id}]} {
                    putquick "PRIVMSG $chan :Error: $id doesn't exist in the database."
                } else {
                    todo eval {DELETE FROM todo WHERE rowid=$id}
                    putquick "PRIVMSG $chan :Deleted todo with ID <$id>."
                }
            }
        }
        todo close
        return -code return
    }

    proc edit {nick chan id text} {
        variable database
        sqlite3 todo $database
        if {![todo exists {SELECT timestamp FROM todo WHERE rowid=$id}]} {
            putquick "PRIVMSG $chan :Error: $id doesn't exist in the database."
        } else {
            todo eval {UPDATE todo SET todotext=$text, author=$nick WHERE rowid=$id}
            putquick "PRIVMSG $chan :todo <$id> updated to: $text"
        }
        todo close
        return -code return
    }

    proc fix {chan text} {
        variable database
        set argv [split $text]
        sqlite3 todo $database
        foreach id $argv {
            if {![string is integer $id]} {
                putquick "PRIVMSG $chan :Error: $id is not a valid number."
            } else {
                if {![todo exists {SELECT timestamp FROM todo WHERE rowid=$id}]} {
                    putquick "PRIVMSG $chan :Error: $id doesn't exist in the database."
                } else {
                    todo eval {UPDATE todo SET fixed="1" WHERE rowid=$id}
                    putquick "PRIVMSG $chan :Marked todo with ID <$id> as fixed."
                }
            }
        }
        todo close
        return -code return
    }

    proc help {chan} {
        variable trigger_todo
        putquick "PRIVMSG $chan :$trigger_todo :: Shows all todos which haven't been fixed yet."
        putquick "PRIVMSG $chan :$trigger_todo fixed :: Shows all todos which have been fixed."
        putquick "PRIVMSG $chan :$trigger_todo add <text> :: Add <text> to database."
        putquick "PRIVMSG $chan :$trigger_todo del <ID> :: Specify one or more IDs separated by spaces to delete todos."
        putquick "PRIVMSG $chan :$trigger_todo fix <ID> :: Specify one or more IDs separated by spaces to mark todos as fixed."
        putquick "PRIVMSG $chan :$trigger_todo mod <ID> <text> :: Update the todo <ID> to <text>."
        putquick "PRIVMSG $chan :$trigger_todo help :: You're reading it."
        return -code return
    }

    proc show {chan fixed} {
        variable database
        sqlite3 todo $database
        if {![todo exists {SELECT timestamp FROM todo WHERE fixed=$fixed LIMIT 1}]} {
            putquick "PRIVMSG $chan :Error: Database is empty."
        } else {
            todo eval {SELECT rowid,todotext,timestamp,author FROM todo WHERE fixed=$fixed ORDER BY timestamp ASC} {
                putquick "PRIVMSG $chan :$rowid - [clock format $timestamp -format "%Y-%m-%d"] - $todotext - $author"
            }
        }
        todo close
        return -code return
    }
}

putlog "bane-todo.tcl"
