// SPDX-License-Identifier: GPL-2.0-only
/* This file is part of lide.device
 * Copyright (C) 2023 Matthew Harlum <matt@harlum.net>
 */
#ifndef _ATAPI_H
#define _ATAPI_H

#include <stdbool.h>
#include "device.h"
#include <exec/types.h>

#define atapi_flag_cd (1<<0)
#define atapi_flag_io (1<<1)

#define atapi_err_abort (1<<2)
#define atapi_err_eom   (1<<1)
#define atapi_err_len   (1<<0)

#define ATAPI_CMD_PACKET   0xA0
#define ATAPI_CMD_IDENTIFY 0xA1

#define ATAPI_DRQ_WAIT_LOOP_US 50
#define ATAPI_DRQ_WAIT_MS 10
#define ATAPI_DRQ_WAIT_COUNT (ATAPI_DRQ_WAIT_MS * (1000 / ATAPI_DRQ_WAIT_LOOP_US))

#define ATAPI_BSY_WAIT_LOOP_US 50
#define ATAPI_BSY_WAIT_S 5
#define ATAPI_BSY_WAIT_COUNT (ATAPI_BSY_WAIT_S * 1000 * (1000 / ATAPI_BSY_WAIT_LOOP_US))

#define ATAPI_RDY_WAIT_LOOP_US 50
#define ATAPI_RDY_WAIT_S 1
#define ATAPI_RDY_WAIT_COUNT (ATAPI_RDY_WAIT_S * 1000 * (1000 / ATAPI_RDY_WAIT_LOOP_US))

void atapi_dev_reset(struct IDEUnit *unit);
bool atapi_check_signature(struct IDEUnit *unit);
bool atapi_identify(struct IDEUnit *unit, UWORD *buffer);
BYTE atapi_translate(APTR io_Data,ULONG lba, ULONG count, ULONG *io_Actual, struct IDEUnit *unit, enum xfer_dir direction);
BYTE atapi_packet(struct SCSICmd *cmd, struct IDEUnit *unit);
BYTE atapi_test_unit_ready(struct IDEUnit *unit);
BYTE atapi_get_capacity(struct IDEUnit *unit);
BYTE atapi_request_sense(struct IDEUnit *unit, UBYTE *errorCode, UBYTE *senseKey, UBYTE *asc, UBYTE *asq);
BYTE atapi_mode_sense(struct IDEUnit *unit, BYTE page_code, UWORD *buffer, UWORD length, UWORD *actual);
BYTE atapi_scsi_mode_sense_6(struct SCSICmd *cmd, struct IDEUnit *unit);
BYTE atapi_start_stop_unit(struct IDEUnit *unit, bool start, bool loej);
BYTE atapi_check_wp(struct IDEUnit *unit);
bool atapi_update_presence(struct IDEUnit *unit, bool present);
#endif