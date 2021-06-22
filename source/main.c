#include <errno.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static unsigned long counter = 0;

unsigned long inner(unsigned long counter) {
#ifdef WITH_PAUSE
  puts("inner() called");
#endif /* WITH_PAUSE */

  return ++counter;
}

unsigned long outer(unsigned long counter) {
#ifdef WITH_PAUSE
  puts("outer() called");
#endif /* WITH_PAUSE */

  return inner(counter) % 1024;
}

static bool running = true;

#ifdef WITH_PAUSE
static sem_t continue_semaphore;
#endif /* WITH_PAUSE */

void *thread_func(void *data) {
  (void)data;

  while (running) {
    counter = outer(counter);

#ifdef WITH_PAUSE
  restart_sem_wait:
    if (sem_wait(&continue_semaphore) < 0) {
      if (errno == EINTR) {
        goto restart_sem_wait;
      }

      perror("sem_wait");
      break;
    }
#endif /* WITH_PAUSE */
  }

  return NULL;
}

#define THREAD_COUNT 1

int main() {
  printf("inner -> %p\n", inner);
  printf("outer -> %p\n", outer);
  printf("thread_func -> %p\n", thread_func);
  printf("\n");

  pthread_t threads[THREAD_COUNT];

#ifdef WITH_PAUSE
  if (sem_init(&continue_semaphore, 0, 0) < 0) {
    perror("sem_init");
    exit(1);
  }
#endif /* WITH_PAUSE */

  for (int i = 0; i < THREAD_COUNT; i++) {
    errno = pthread_create(&threads[i], NULL, thread_func, NULL);
    if (errno != 0) {
      perror("pthread_create");
      exit(1);
    }
  }

  while (1) {
    char c = getchar();

#ifdef WITH_PAUSE
    for (int i = 0; i < THREAD_COUNT; i++) {
      if (sem_post(&continue_semaphore) < 0) {
        perror("sem_post");
        exit(1);
      }
    }
#endif /* WITH_PAUSE */

    if (c == 'q') {
    exit(1);
      break;
    }
  }

  running = false;

  for (int i = 0; i < THREAD_COUNT; i++) {
    errno = pthread_join(threads[i], NULL);
    if (errno != 0) {
      perror("pthread_join");
      exit(1);
    }
  }

#ifdef WITH_PAUSE
  if (sem_destroy(&continue_semaphore) < 0) {
    perror("sem_destroy");
    exit(1);
  }
#endif /* WITH_PAUSE */

  printf("final counter value is %ld\n", counter);

  return 0;
}
