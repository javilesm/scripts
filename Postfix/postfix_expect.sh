#!/usr/bin/expect -f
# postfix_expect.sh
set timeout -1
spawn dpkg-reconfigure postfix

expect "General type of mail configuration:"
send -- "Internet Site\r"

expect "System mail name:"
send -- "example.com\r"

expect "Root and postmaster mail recipient:"
send -- "admin@example.com\r"

expect "Other destinations to accept mail for (blank for none):"
send -- "\r"

expect "Force synchronous updates on mail queue?"
send -- "No\r"

expect "Local networks:"
send -- "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128\r"

expect "Use procmail for local delivery?"
send -- "Yes\r"

expect "Mailbox size limit (bytes) (0 for no limit):"
send -- "0\r"

expect "Local address extension character:"
send -- "+\r"

expect eof
