#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

int main(int argc, char *argv[]) {
    char *here = getenv("APPDIR");
    if (!here) {
        // Try to get current directory
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            here = cwd;
        } else {
            here = ".";
        }
    }
    
    // Set up environment
    char python_path[2048];
    char script_path[2048];
    char ld_path[2048];
    
    snprintf(python_path, sizeof(python_path), "%s/usr/bin/python3", here);
    snprintf(script_path, sizeof(script_path), "%s/usr/share/hosts-studio/hosts_studio.py", here);
    snprintf(ld_path, sizeof(ld_path), "%s/usr/lib", here);
    
    // Set environment variables
    setenv("LD_LIBRARY_PATH", ld_path, 1);
    
    // Check if we're root
    if (getuid() == 0) {
        // Already root, run the Python script directly
        execl(python_path, "python3", script_path, NULL);
        perror("Failed to execute python3");
        return 1;
    } else {
        // Need to escalate privileges
        // Try pkexec first
        char *pkexec_args[] = {
            "pkexec",
            "env",
            "DISPLAY", getenv("DISPLAY") ? getenv("DISPLAY") : ":0",
            "XAUTHORITY", getenv("XAUTHORITY") ? getenv("XAUTHORITY") : "",
            "DBUS_SESSION_BUS_ADDRESS", getenv("DBUS_SESSION_BUS_ADDRESS") ? getenv("DBUS_SESSION_BUS_ADDRESS") : "",
            python_path,
            script_path,
            NULL
        };
        
        execvp("pkexec", pkexec_args);
        
        // If pkexec fails, try gksudo
        char *gksudo_args[] = {
            "gksudo",
            "--",
            python_path,
            script_path,
            NULL
        };
        
        execvp("gksudo", gksudo_args);
        
        // If gksudo fails, try kdesudo
        char *kdesudo_args[] = {
            "kdesudo",
            "--",
            python_path,
            script_path,
            NULL
        };
        
        execvp("kdesudo", kdesudo_args);
        
        // If all fail, show error
        fprintf(stderr, "This application requires root privileges to modify /etc/hosts.\n");
        fprintf(stderr, "Please run with: sudo DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY %s\n", argv[0]);
        return 1;
    }
} 