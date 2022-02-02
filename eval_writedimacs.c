#include <stdio.h>
#include <string.h>
#include <time.h>

int main(int argc, char* argv) {
    char *line = NULL;
    size_t len = 0;
    ssize_t lineSize = 0;
    struct timespec begin, end;

    while (!feof(stdin)) {
        lineSize = getline(&line, &len, stdin);
        printf("%s", line);

        if (strcmp("writing dimacs\n", line) == 0)
            clock_gettime(CLOCK_REALTIME, &begin);

        if (strcmp("done.\n", line) == 0) {
            clock_gettime(CLOCK_REALTIME, &end);
            long seconds = end.tv_sec - begin.tv_sec;
            long nanoseconds = end.tv_nsec - begin.tv_nsec;
            unsigned long long elapsed = seconds *1e+9 + nanoseconds;
            printf("c eval_writedimacs=%llu\n", elapsed);
            return 0;
        }
    }
}