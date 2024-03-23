/* main.c - Application main entry point */
/* Reads and reports ambient light value */

/*
 * Copyright (c) 2015-2016 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/byteorder.h>
#include <zephyr/kernel.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/drivers/sensor/veml7700.h>
#include <zephyr/device.h>

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>
#include <zephyr/bluetooth/services/bas.h>
#include <zephyr/bluetooth/services/ias.h>
#include "ess.h"

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_UUID16_ALL,
				  BT_UUID_16_ENCODE(BT_UUID_ESS_VAL),
				  BT_UUID_16_ENCODE(BT_UUID_BAS_VAL),
				  BT_UUID_16_ENCODE(BT_UUID_DIS_VAL))};

static void connected(struct bt_conn *conn, uint8_t err)
{
	if (err)
	{
		printk("Connection failed (err 0x%02x)\n", err);
	}
	else
	{
		printk("Connected\n");
	}
}

static void disconnected(struct bt_conn *conn, uint8_t reason)
{
	printk("Disconnected (reason 0x%02x)\n", reason);
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
	.connected = connected,
	.disconnected = disconnected,
};

static void bt_ready(void)
{
	int err;

	printk("Bluetooth initialized\n");

	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);
	if (err)
	{
		printk("Advertising failed to start (err %d)\n", err);
		return;
	}

	printk("Advertising successfully started\n");
}

static void auth_cancel(struct bt_conn *conn)
{
	char addr[BT_ADDR_LE_STR_LEN];

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));

	printk("Pairing cancelled: %s\n", addr);
}

static struct bt_conn_auth_cb auth_cb_display = {
	.cancel = auth_cancel,
};

static void bas_notify(void)
{
	uint8_t battery_level = bt_bas_get_battery_level();

	battery_level--;

	if (!battery_level)
	{
		battery_level = 100U;
	}

	bt_bas_set_battery_level(battery_level);
}

static const struct device *get_veml7700_device(void)
{
	const struct device *const dev = DEVICE_DT_GET_ANY(vishay_veml7700);

	if (dev == NULL)
	{
		/* No such node, or the node does not have status "okay". */
		printk("\nError: no device found.\n");
		return NULL;
	}

	if (!device_is_ready(dev))
	{
		printk("\nError: Device \"%s\" is not ready; "
			   "check the driver initialization logs for errors.\n",
			   dev->name);
		return NULL;
	}

	printk("Found device \"%s\", getting sensor data\n", dev->name);
	return dev;
}

int main(void)
{
	int err;

	err = bt_enable(NULL);
	if (err)
	{
		printk("Bluetooth init failed (err %d)\n", err);
		return 0;
	}

	bt_ready();

	bt_conn_auth_cb_register(&auth_cb_display);

	const struct device *dev = get_veml7700_device();
	struct sensor_value ambient_light;

	// Need to set gain levels for high lux value
	// Can also override driver constructor if nedded
	if (sensor_attr_set(dev, SENSOR_CHAN_LIGHT, SENSOR_ATTR_VEML7700_GAIN, VEML7700_ALS_GAIN_1_8) != 0)
	{
		return 0;
	};
	if(sensor_attr_set(dev, SENSOR_CHAN_LIGHT, SENSOR_ATTR_VEML7700_ITIME, VEML7700_ALS_IT_25) != 0)
	{
		return 0;
	};

	if (dev == NULL)
	{
		printk("Device not found");
		return 0;
	}


	while (1)
	{
		sensor_sample_fetch(dev);
		sensor_channel_get(dev, SENSOR_CHAN_LIGHT, &ambient_light);
		printk("lux: %d\n",
			   ambient_light.val1);

		// Update Light level
		bt_ess_set_light_level(ambient_light.val1);

		// Not implemented just a simulation
		bas_notify();

		k_sleep(K_SECONDS(1));
	}
	return 0;
}
