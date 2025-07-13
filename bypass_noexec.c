#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <string.h>
#include <errno.h>
#include <libgen.h>

#define MAX_PATH 4096
#define TEMP_DIR "/tmp/hosts-studio"

int is_noexec_mount(const char *path) {
    FILE *fp;
    char line[1024];
    char mount_point[MAX_PATH];
    char mount_info[MAX_PATH];
    
    // Get mount point
    snprintf(mount_info, sizeof(mount_info), "df %s | tail -1 | awk '{print $6}'", path);
    fp = popen(mount_info, "r");
    if (!fp) return 0;
    
    if (fgets(mount_point, sizeof(mount_point), fp)) {
        mount_point[strcspn(mount_point, "\n")] = 0;
        pclose(fp);
        
        // Check if mount has noexec
        snprintf(mount_info, sizeof(mount_info), "mount | grep '%s' | grep -q noexec", mount_point);
        return system(mount_info) == 0;
    }
    
    pclose(fp);
    return 0;
}

int copy_directory(const char *src, const char *dst) {
    char cmd[MAX_PATH * 2];
    snprintf(cmd, sizeof(cmd), "cp -r '%s' '%s'", src, dst);
    return system(cmd);
}

int main(int argc, char *argv[]) {
    char appdir[MAX_PATH];
    char python_path[MAX_PATH];
    char script_path[MAX_PATH];
    char temp_dir[MAX_PATH];
    char *here;
    
    // Get AppDir path
    here = getenv("APPDIR");
    if (!here) {
        char cwd[MAX_PATH];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            here = cwd;
        } else {
            here = ".";
        }
    }
    
    snprintf(appdir, sizeof(appdir), "%s", here);
    
    // Check if we're on a noexec mount
    if (is_noexec_mount(appdir)) {
        printf("Detected noexec mount, copying to writable location...\n");
        
        // Create temp directory
        snprintf(temp_dir, sizeof(temp_dir), "%s-%d", TEMP_DIR, getpid());
        mkdir(temp_dir, 0755);
        
        // Copy necessary files
        snprintf(python_path, sizeof(python_path), "%s/usr", appdir);
        snprintf(script_path, sizeof(script_path), "%s/usr/share/hosts-studio", appdir);
        
        if (copy_directory(python_path, temp_dir) != 0) {
            fprintf(stderr, "Failed to copy files to temp directory\n");
            return 1;
        }
        
        // Set environment variables
        char ld_path[MAX_PATH];
        snprintf(ld_path, sizeof(ld_path), "%s/usr/lib", temp_dir);
        setenv("LD_LIBRARY_PATH", ld_path, 1);
        
        // Execute from temp directory
        snprintf(python_path, sizeof(python_path), "%s/usr/bin/python3", temp_dir);
        snprintf(script_path, sizeof(script_path), "%s/usr/share/hosts-studio/hosts_studio.py", temp_dir);
        
        execl(python_path, "python3", script_path, NULL);
        perror("Failed to execute python3");
        return 1;
    }
    
    // Normal execution path
    snprintf(python_path, sizeof(python_path), "%s/usr/bin/python3", appdir);
    snprintf(script_path, sizeof(script_path), "%s/usr/share/hosts-studio/hosts_studio.py", appdir);
    
    // Set environment variables
    char ld_path[MAX_PATH];
    snprintf(ld_path, sizeof(ld_path), "%s/usr/lib", appdir);
    setenv("LD_LIBRARY_PATH", ld_path, 1);
    
    execl(python_path, "python3", script_path, NULL);
    perror("Failed to execute python3");
    return 1;
} 