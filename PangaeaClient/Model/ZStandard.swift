//
//  ZStandard.swift
//  PangaeaClient
//
//  Created by Heiko Pälike on 20/03/2019.
//  Copyright © 2019 Heiko Pälike. All rights reserved.
//

import Foundation
import Zstandard

public enum ZstdError : Error {
	case error(String)
}

func compress(data: Data, compressionLevel : Int = 17) throws -> Data {
	let maxLength = ZSTD_compressBound(data.count)
	let destBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: maxLength, alignment: MemoryLayout<UInt8>.alignment)
	
	defer {
		destBuffer.deallocate()
	}
	
	guard let destBufferBase = destBuffer.baseAddress else {
		throw ZstdError.error("error allocating destination buffer in Zstd.compress")
	}
	
	return try data.withUnsafeBytes({bufferPointer throws -> Data in
		
		let compressedSize = ZSTD_compress(destBuffer.baseAddress, maxLength, bufferPointer.baseAddress, data.count, Int32(compressionLevel))
		guard compressedSize >= 0 else {
			throw ZstdError.error( ZSTD_isError(compressedSize)>0 ? String(cString: ZSTD_getErrorName(compressedSize)) : "unknown ZstdError")
		}
		
		return Data(bytes: destBufferBase, count: compressedSize)
	})
	
}

func decompress(compressedData: Data) throws -> Data {
	return try compressedData.withUnsafeBytes({ srcBufferPointer throws -> Data in
		let decompSize = Int(ZSTD_getDecompressedSize(srcBufferPointer.baseAddress, compressedData.count))
		let destBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: decompSize, alignment: MemoryLayout<UInt8>.alignment)
		
		defer {
			destBuffer.deallocate()
		}
		
		guard let destBufferBase = destBuffer.baseAddress else {
			throw ZstdError.error("error allocating destination buffer in Zstd.compress")
		}
		let decompressedSizeActual = ZSTD_decompress(destBufferBase, decompSize, srcBufferPointer.baseAddress, compressedData.count)
		
		guard decompressedSizeActual >= 0 else {
			throw ZstdError.error( ZSTD_isError(decompressedSizeActual)>0 ? String(cString: ZSTD_getErrorName(decompressedSizeActual)) : "unknown ZstdError")
		}
		
		return Data(bytes: destBufferBase, count: decompressedSizeActual)
		
	})
}