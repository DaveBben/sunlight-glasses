/** @file
 *  @brief Environment Sensing Service
 */

/*
 * Copyright (c) 2018 Nordic Semiconductor ASA
 * Copyright (c) 2016 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <errno.h>
#include <zephyr/init.h>
#include <zephyr/sys/__assert.h>
#include <stdbool.h>
#include <zephyr/types.h>
#include "math.h"

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/bluetooth/uuid.h>
#include "ess.h"

#define LOG_LEVEL CONFIG_BT_ESS_LOG_LEVEL
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(ess);

static int32_t light_level = 100U;

static void blvl_ccc_cfg_changed(const struct bt_gatt_attr *attr,
				       uint16_t value)
{
	ARG_UNUSED(attr);

	bool notif_enabled = (value == BT_GATT_CCC_NOTIFY);

	LOG_INF("ESS Notifications %s", notif_enabled ? "enabled" : "disabled");
}

static ssize_t read_lvl(struct bt_conn *conn,
			       const struct bt_gatt_attr *attr, void *buf,
			       uint16_t len, uint16_t offset)
{
	int32_t lvl8 = light_level;

	return bt_gatt_attr_read(conn, attr, buf, len, offset, &lvl8,
				 sizeof(lvl8));
}

BT_GATT_SERVICE_DEFINE(ess,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_ESS),
	BT_GATT_CHARACTERISTIC(BT_UUID_GATT_PERLGHT,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
			       BT_GATT_PERM_READ, read_lvl, NULL,
			       &light_level),
	BT_GATT_CCC(blvl_ccc_cfg_changed,
		    BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
);

static int ess_init(void)
{

	return 0;
}

int32_t bt_ess_get_light_level(void)
{
	return light_level;
}

int bt_ess_set_light_level(int32_t level)
{
	int rc;

	if (level < 0) {
		return -EINVAL;
	}

	// Source Adafruit
	float lux_corrected = (((6.0135e-13 * level - 9.3924e-9) * level + 8.1488e-5) * level + 1.0023) *
          level;

	light_level = (int32_t) lux_corrected;

	rc = bt_gatt_notify(NULL, &ess.attrs[1], &light_level, sizeof(light_level));

	return rc == -ENOTCONN ? 0 : rc;
}

SYS_INIT(ess_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
