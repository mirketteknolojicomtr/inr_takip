package com.mirketteknoloji.inrtakip

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Cihaz kilitliyken de (apduservice.xml: requireDeviceUnlock=false, API 33+)
 * OS tarafından tetiklenen, karşı cihaza acil tıbbi bilgiyi bir NFC Forum
 * Type 4 Tag (NDEF) olarak sunan Host Card Emulation servisi.
 *
 * SELECT AID / SELECT File / READ BINARY komutlarını işleyen standart
 * Type 4 Tag durum makinesi. Yayınlanan metin [updatePayload] ile
 * Flutter tarafından (bkz. MainActivity.kt'deki MethodChannel) güncellenir.
 */
class InrHceService : HostApduService() {

    companion object {
        private val AID_NDEF_TAG = hexStringToByteArray("D2760000850101")
        private val CAPABILITY_CONTAINER_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val STATUS_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
        private val STATUS_INSTRUCTION_NOT_SUPPORTED = byteArrayOf(0x6D, 0x00)

        @Volatile
        private var payloadText: String =
            "INR Takip: acil bilgi henüz senkronize edilmedi."

        /** Flutter tarafından (LockScreenSyncService/NfcEmergencyService) çağrılır. */
        fun updatePayload(text: String) {
            payloadText = text
        }

        private fun hexStringToByteArray(hex: String): ByteArray {
            val result = ByteArray(hex.length / 2)
            for (i in result.indices) {
                val index = i * 2
                result[i] = ((Character.digit(hex[index], 16) shl 4) +
                        Character.digit(hex[index + 1], 16)).toByte()
            }
            return result
        }
    }

    private var selectedFile: ByteArray? = null

    private fun buildNdefMessage(): ByteArray {
        val lang = "tr"
        val langBytes = lang.toByteArray(Charsets.US_ASCII)
        val textBytes = payloadText.toByteArray(Charsets.UTF_8)
        // Status byte: bit7=0 (UTF-8 kodlama), bit0-5: dil kodu uzunluğu.
        val status = langBytes.size.toByte()
        val payload = byteArrayOf(status) + langBytes + textBytes

        // MB=1, ME=1, SR=1 (short record), TNF=001 (well-known) -> 0xD1
        return byteArrayOf(0xD1.toByte(), 0x01, payload.size.toByte(), 0x54) + payload
    }

    private fun buildNdefFile(): ByteArray {
        val message = buildNdefMessage()
        val nlen = message.size
        return byteArrayOf((nlen shr 8).toByte(), (nlen and 0xFF).toByte()) + message
    }

    private fun buildCapabilityContainer(ndefFileSize: Int): ByteArray = byteArrayOf(
        0x00, 0x0F, // CCLEN = 15
        0x20, // Mapping Version 2.0
        0x00, 0x3B, // MLe
        0x00, 0x34, // MLc
        0x04, 0x06, // NDEF-File-Control-TLV: tag, uzunluk
        NDEF_FILE_ID[0], NDEF_FILE_ID[1],
        (ndefFileSize shr 8).toByte(), (ndefFileSize and 0xFF).toByte(),
        0x00, // okuma erişimi: serbest
        0xFF.toByte(), // yazma erişimi: yok (salt okunur)
    )

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val apdu = commandApdu
        if (apdu == null || apdu.size < 4) return STATUS_INSTRUCTION_NOT_SUPPORTED

        return when (apdu[1]) {
            0xA4.toByte() -> handleSelect(apdu)
            0xB0.toByte() -> handleReadBinary(apdu)
            else -> STATUS_INSTRUCTION_NOT_SUPPORTED
        }
    }

    private fun handleSelect(apdu: ByteArray): ByteArray {
        val p1 = apdu[2]
        val lc = apdu[4].toInt() and 0xFF
        val field = apdu.copyOfRange(5, (5 + lc).coerceAtMost(apdu.size))

        // SELECT AID (P1=04): uygulamayı seç.
        if (p1 == 0x04.toByte()) {
            if (!field.contentEquals(AID_NDEF_TAG)) return STATUS_FILE_NOT_FOUND
            selectedFile = null
            return STATUS_SUCCESS
        }

        // SELECT File by ID (P1=00): CC ya da NDEF dosyasını seç.
        return when {
            field.contentEquals(CAPABILITY_CONTAINER_FILE_ID) -> {
                selectedFile = buildCapabilityContainer(buildNdefFile().size)
                STATUS_SUCCESS
            }
            field.contentEquals(NDEF_FILE_ID) -> {
                selectedFile = buildNdefFile()
                STATUS_SUCCESS
            }
            else -> STATUS_FILE_NOT_FOUND
        }
    }

    private fun handleReadBinary(apdu: ByteArray): ByteArray {
        val file = selectedFile ?: return STATUS_FILE_NOT_FOUND
        val offset = ((apdu[2].toInt() and 0xFF) shl 8) or (apdu[3].toInt() and 0xFF)
        val length = apdu[4].toInt() and 0xFF
        if (offset >= file.size) return STATUS_FILE_NOT_FOUND

        val end = (offset + length).coerceAtMost(file.size)
        return file.copyOfRange(offset, end) + STATUS_SUCCESS
    }

    override fun onDeactivated(reason: Int) {
        selectedFile = null
    }
}
