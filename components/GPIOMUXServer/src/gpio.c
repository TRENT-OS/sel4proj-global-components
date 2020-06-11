/*
 * Copyright 2019, Data61
 * Commonwealth Scientific and Industrial Research Organisation (CSIRO)
 * ABN 41 687 119 230.
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(DATA61_BSD)
 */

#include <assert.h>
#include <stdio.h>
#include <stdbool.h>
#include <errno.h>
#include <camkes/io.h>
#include <camkes/irq.h>
#include <platsupport/io.h>
#include <platsupport/irq.h>
#include <utils/util.h>

#include <platsupport/gpio.h>
#include <gpiomuxserver_plat.h>

#include "gpio.h"

/* State management for the pins */
typedef struct gpio_entry {
    bool initialised;
    seL4_Word owner;
    gpio_t gpio;
} gpio_entry_t;

/*
 * Gotchas:
 *  - we assume that all boards that we support has an mux controller, if some
 *  pins are turned off as a result of conflicting pins via the mux, we don't
 *  actually alert the user about this, it's up to the user to not shoot
 *  themselves in the foot
 *  - on implementations that have a working 'set_next' function, we will
 *  write/read partially if there are any errors in the middle of the operation
 *  (e.g. severed link). i.e. this operation is not transactional
 *  - the pins are first come first served, and there is no way to disable the pins
 */

/* GPIO control structure for initialising pins */
static gpio_sys_t gpio_sys;
/* table for keeping track of ownership of GPIO pins */
static size_t gpio_table_size;
static gpio_entry_t *gpio_table;

/* Prototypes for these functions are not generated by the camkes templates yet */
seL4_Word the_gpio_get_sender_id();

static inline bool check_valid_gpio_id(gpio_id_t pin_id)
{
    return (pin_id < 0 || pin_id >= gpio_table_size) ? false : true;
}

static inline bool check_pin_initialised(gpio_id_t pin_id)
{
    return gpio_table[pin_id].initialised ? true : false;
}

static inline bool check_client_owns_pin(gpio_id_t pin_id, seL4_Word client_id)
{
    return gpio_table[pin_id].owner == client_id;
}

static inline seL4_Word get_client_id(void)
{
    return the_gpio_get_sender_id();
}

int the_gpio_init_pin(gpio_id_t pin_id, gpio_dir_t dir)
{

    int error = 0;

    if (!check_valid_gpio_id(pin_id)) {
        error = -EINVAL;
        goto out;
    }

    if (GPIO_DIR_IRQ_LOW <= dir && dir <= GPIO_DIR_IRQ_EDGE) {
        ZF_LOGE("Setting GPIO pins as interrupt sources is not currently supported");
        error = -EINVAL;
        goto out;
    }

    /* check if the caller owns the pin */
    seL4_Word client_id = get_client_id();
    if (check_client_owns_pin(pin_id, client_id)) {
        error = 0;
        goto out;
    }

    /* check if anyone has reserved the pin */
    if (the_gpio_get_pin_assignee(client_id) != 0) {
        error = -EBUSY;
        goto out;
    }

    /* check if anyone else has the pin */
    if (check_pin_initialised(pin_id)) {
        error = -EBUSY;
        goto out;
    }

    gpio_entry_t *gpio_entry = &gpio_table[pin_id];

    error = gpio_new(&gpio_sys, pin_id, dir, &gpio_entry->gpio);
    if (error) {
        goto out;
    }

    gpio_entry->initialised = true;
    gpio_entry->owner = client_id;

out:
    return error;
}

int the_gpio_set_level(gpio_id_t pin_id, gpio_level_t level)
{

    seL4_Word client_id = get_client_id();
    int error = 0;

    if (!check_valid_gpio_id(pin_id)) {
        error = -EINVAL;
        goto out;
    }

    if (!check_client_owns_pin(pin_id, client_id)) {
        error = -EINVAL;
        goto out;
    }

    if (level == GPIO_LEVEL_HIGH) {
        error = gpio_set(&gpio_table[pin_id].gpio);
    } else if (level == GPIO_LEVEL_LOW) {
        error = gpio_clr(&gpio_table[pin_id].gpio);
    } else {
        /* level < 0 is not valid */
        error = -EINVAL;
    }

out:
    return error;
}

int the_gpio_read_level(gpio_id_t pin_id)
{

    seL4_Word client_id = get_client_id();
    int ret = 0;

    if (!check_valid_gpio_id(pin_id)) {
        ret = -EINVAL;
        goto out;
    }

    if (!check_client_owns_pin(pin_id, client_id)) {
        ret = -EINVAL;
        goto out;
    }

    ret = gpio_get(&gpio_table[pin_id].gpio);

out:
    return ret;
}

int gpio_component_init(ps_io_ops_t *io_ops)
{
    int error = gpio_sys_init(io_ops, &gpio_sys);
    if (error) {
        ZF_LOGE("Failed to initialise GPIO subsystem");
        return error;
    }

    gpio_table_size = MAX_GPIO_ID + 1;
    error = ps_calloc(&io_ops->malloc_ops, 1, sizeof(*gpio_table) * gpio_table_size, (void **) &gpio_table);
    if (error) {
        ZF_LOGE("Failed to allocate memory for the table of GPIO pins");
        return error;
    }

    for (int i = 0; i < gpio_table_size; i++) {
        gpio_table[i].owner = -1;
    }

    return 0;
}
