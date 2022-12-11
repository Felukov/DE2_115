#include "kernel.h"
#include "kbd.h"
#include "x86.h"
#include "terminal.h"
#include "rnd.h"

#define KBD_UP 1
#define KBD_DOWN 2
#define KBD_LEFT 3
#define KBD_RIGHT 4
#define KBD_PAUSE 5

typedef struct {
    uint8_t x;
    uint8_t y;
    uint8_t last;
} snake_part_t;

snake_part_t snake_body[22*78];

uint8_t fruits[25][80];

uint16_t delay = 33144/2;
uint8_t  cnt = 0;
uint8_t  old_cmd = KBD_UP;
uint8_t  release_code = 0;
uint8_t  ch = 0;

int snake_len = -1;

void print_border(){
    int i = 0;

    for (i = 2; i < 24; i++) {
        terminal_print_v(0,  i, 20, "|");
        terminal_print_v(79, i, 20, "|");
    }

    for (i = 0; i < 80; i++) {
        terminal_print_h(i,  1, 20, "-");
        terminal_print_h(i, 24, 20, "-");
    }

    terminal_print_h(0,  1, 20, "+");
    terminal_print_h(79, 1, 20, "+");

    terminal_print_h(0,  24, 20, "+");
    terminal_print_h(79, 24, 20, "+");

}

void snake_body_init(){
    snake_body[0].x = 40;
    snake_body[0].y = 10;
    snake_body[0].last = 0;

    snake_body[1].x = 40;
    snake_body[1].y = 11;
    snake_body[1].last = 0;

    snake_body[2].x = 40;
    snake_body[2].y = 12;
    snake_body[2].last = 0;

    snake_body[3].x = 41;
    snake_body[3].y = 12;
    snake_body[3].last = 0;

    snake_body[4].x = 42;
    snake_body[4].y = 12;
    snake_body[4].last = 1;

    snake_len = 5;
}

void snake_body_draw(){
    uint16_t i = 0;

    do {

        terminal_print_h(snake_body[i].x, snake_body[i].y, 20, "*");

        if (snake_body[i].last) {
            break;
        }
        i++;

    } while (1 == 1);

}

void snake_body_clear(){
    uint16_t i = 0;

    do {

        terminal_print_h(snake_body[i].x, snake_body[i].y, 20, " ");
        if (snake_body[i].last) {
            break;
        }
        i++;

    } while (1 == 1);
}

void snake_check_food(){
    if (fruits[snake_body[0].y][snake_body[0].x] == 'o') {
        snake_body[snake_len].x = snake_body[snake_len-1].x;
        snake_body[snake_len].y = snake_body[snake_len-1].y;
        snake_body[snake_len].last = 1;
        snake_body[snake_len-1].last = 0;
        fruits[snake_body[0].y][snake_body[0].x] = '_';
        if (cnt == 9) {
            delay -= delay/25;
            cnt=0;
        } else {
            cnt++;
        }
        snake_len++;
    }
}

void snake_body_move_up(){
    uint16_t i = snake_len - 1;

    snake_body_clear();
    snake_check_food();

    do {
        snake_body[i].x = snake_body[i-1].x;
        snake_body[i].y = snake_body[i-1].y;

        if (i == 1) {
            break;
        }
        i--;
    } while (1 == 1);

    snake_body[0].y = snake_body[0].y - 1;

    snake_body_draw();
}

void snake_body_move_left(){
    uint16_t i = snake_len - 1;

    snake_body_clear();
    snake_check_food();

    do {
        snake_body[i].x = snake_body[i-1].x;
        snake_body[i].y = snake_body[i-1].y;

        if (i == 1) {
            break;
        }
        i--;
    } while (1 == 1);

    snake_body[0].x = snake_body[0].x - 1;

    snake_body_draw();
}

void snake_body_move_down(){
    uint16_t i = snake_len - 1;

    snake_body_clear();
    snake_check_food();

    do {
        snake_body[i].x = snake_body[i-1].x;
        snake_body[i].y = snake_body[i-1].y;

        if (i == 1) {
            break;
        }
        i--;
    } while (1 == 1);

    snake_body[0].y = snake_body[0].y + 1;

    snake_body_draw();
}

void snake_body_move_right(){
    uint16_t i = snake_len - 1;

    snake_body_clear();
    snake_check_food();

    do {
        snake_body[i].x = snake_body[i-1].x;
        snake_body[i].y = snake_body[i-1].y;

        if (i == 1) {
            break;
        }
        i--;
    } while (1 == 1);

    snake_body[0].x = snake_body[0].x + 1;

    snake_body_draw();
}

void wait_time(){
    //kernel_wait(33144);
    kernel_wait(delay);
    //kernel_wait(10);
}

uint8_t decode_kbd(){
    uint8_t  cmd = 0;

    while (kbd_has_data()){
        ch = kbd_read_char();

        if (ch == 0xE0) {
            // enchanced kbd
            // skip
        } else if (ch == 0xF0) {
            // released
            release_code = 1;
            // skip
        } else {
            switch (ch) {
            case 0x75:
                /* code */
                cmd = KBD_UP;
                break;
            case 0x6B:
                /* code */
                cmd = KBD_LEFT;
                break;
            case 0x72:
                /* code */
                cmd = KBD_DOWN;
                break;
            case 0x74:
                /* code */
                cmd = KBD_RIGHT;
                break;
            case 0x29:
                if (release_code == 1) {
                    cmd = KBD_PAUSE;
                }
            default:
                break;
            }
            release_code = 0;
        }
        // _inline_outpw(0x306, cmd);
        // _inline_outpw(0x305, ch);
    }
    return cmd;
}

void clear_food_map(){
    int y = 0;
    int x = 0;

    for (y = 0; y < 25; y++) {
        for (x = 0; x < 80; x++) {
            fruits[y][x] = '_';
        }
    }

}

void make_food(){
    uint8_t x = get_rnd_range(1, 79);
    uint8_t y = get_rnd_range(2, 23);

    uint8_t f = get_rnd();

    if (f % 3 == 0){
        terminal_print_h(x, y, 20, "o");
        fruits[y][x] = 'o';
    }
}

uint8_t collision_detector(){
    uint16_t i = snake_len - 1;

    // check borders
    if (snake_body[0].x == 0 || snake_body[0].x == 79 || snake_body[0].y == 1 || snake_body[0].y == 24){
        return 1;
    }
    // check itself
    do {
        if (snake_body[i].x == snake_body[0].x && snake_body[i].y == snake_body[0].y) {
            return 1;
        }

        if (i == 1) {
            break;
        }
        i--;
    } while (1 == 1);
    return 0;
}

void do_game(){
    uint8_t cmd = KBD_LEFT;
    uint8_t new_cmd = KBD_LEFT;
    clear_food_map();
    terminal_clean();
    terminal_print_h(0, 0, 20, "Snake Game v 1.04l");
    print_border();
    snake_body_init();
    snake_body_draw();

    for (;;) {

        new_cmd = decode_kbd();

        if (new_cmd != 0) {

            if (new_cmd == KBD_PAUSE) {
                if (cmd == KBD_PAUSE) {
                    cmd = old_cmd;
                } else {
                    old_cmd = cmd;
                    cmd = KBD_PAUSE;
                }
            } else {
                if ((cmd == KBD_UP && new_cmd == KBD_DOWN) || (cmd == KBD_LEFT && new_cmd == KBD_RIGHT) ||
                    (cmd == KBD_DOWN && new_cmd == KBD_UP) || (cmd == KBD_RIGHT && new_cmd == KBD_LEFT)) {
                    // illegal combinations
                } else {
                    cmd = new_cmd;
                }
            }
        }


        switch (cmd) {
        case KBD_UP:
            make_food();
            snake_body_move_up();
            break;
        case KBD_DOWN:
            make_food();
            snake_body_move_down();
            break;
        case KBD_LEFT:
            make_food();
            snake_body_move_left();
            break;
        case KBD_RIGHT:
            make_food();
            snake_body_move_right();
            break;
        case KBD_PAUSE:
            cpu_halt();
            //wait_time();
            continue;
        default:
            break;
        }
        wait_time();

        if (collision_detector()) {
            return;
        }

    }
}

int cmain (){
    unsigned int cnt_0 = 1;
    unsigned int cnt_1 = 0;

    char str[3];
    _inline_outpw(0x306, 0);

    kernel_init();
    cnt_0++;
    //_inline_outpw(0x305, cnt_0);

    uart_log("kernel initialization completed\n");
    cnt_0++;
    //_inline_outpw(0x305, cnt_0);

    //_inline_outp(0x60, 0xF2);
    wait_time();

    for (;;){
        rnd_init();
        delay = 33144/2;
        cnt = 0;
        do_game();
        wait_time();
        wait_time();
        wait_time();
        wait_time();
        _inline_outpw(0x306, 0);
    }

    return 0;
}
