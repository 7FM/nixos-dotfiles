myTools:
with myTools; {
    ssh = [
        (defineHiddenPortTCP 22 "ssh_default_port")
    ];
}