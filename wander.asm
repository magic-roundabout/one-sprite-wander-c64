;
; ONE SPRITE WANDER
;

; Code, graphics and music by T.M.R


; This source code is formatted for the ACME cross assembler from
; http://sourceforge.net/projects/acme-crossass/
; Compression is handled with Exomizer which can be downloaded at
; https://csdb.dk/release/?id=167084

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Select an output filename
		!to "wander.prg",cbm


; Yank in binary data
		* = $0400
copyright_spr	!binary "data/copyright.spr"

		* = $0500
music		!binary "data/x-out_loader.sid",,$7e

; Constants: raster positions
rstr1p		= $00
rstr2p		= $2d

bg_colour	= $02

; Labels
rn		= $20
stretch_cnt	= $21

cos_at_1	= $22
cos_at_2	= $23

sprite_data	= $03c0
char_buffer	= $0400
colour_data	= $0408


; Entry point at $0938
		* = $0938
entry		sei

; Kick the ROMs out and set up an interrupt
		lda #$35
		sta $01

		lda #<nmi
		sta $fffa
		lda #>nmi
		sta $fffb

		lda #<int
		sta $fffe
		lda #>int
		sta $ffff

		lda #$7f
		sta $dc0d
		sta $dd0d

		lda #rstr1p
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Set a couple of labels and...
		lda #$01
		sta rn

		lda #$00
		sta stretch_cnt
		sta cos_at_1

		lda #$33
		sta cos_at_2

; ...stash the ghostbyte
		lda $3fff
		sta ghost_store+$01
		lda #$00
		sta $3fff

; Copy the sprite definition down to the tape buffer
		ldx #$00
copyright_copy	lda copyright_spr,x
		sta sprite_data,x

		lda #$00
		sta copyright_spr,x

		inx
		cpx #$40
		bne copyright_copy

; Set up the sprite expansion tables
		ldx #$00
xflex_set_exp	lda sprite_cols,x
		ora #$80
		sta colour_data,x
		inx
		cpx #$c8
		bne xflex_set_exp

; Reset the scrolling message
		jsr reset

; Initialise the music
		lda #$00
		jsr music+$00

		cli

; Check to see if space has been pressed
main_loop	lda $dc01
		cmp #$ef
		beq *+$05
		jmp main_loop

; Reset some registers
		sei
		lda #$37
		sta $01

		lda #$00
		sta $d011
		sta $d020
		sta $d021
		sta $d418

; Restore $3fff
ghost_store	lda #$64
		sta $3fff

; Reset the C64 (a linker would go here...)
		jmp $fce2


; IRQ interrupt
int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne ya
		jmp ea31

ya		lda rn
		cmp #$02
		bne *+$05
		jmp rout2


; Raster split 1
rout1		lda #bg_colour
		sta $d020
		sta $d021
		sta $d02e

		lda #$00
		sta $d018

		lda #$80
		sta $d015
		sta $d017
		sta $d01d

		lda cos_at_1
		clc
		adc #$02
		cmp #$fb
		bcc *+$04
		lda #$05
		sta cos_at_1
		tax

		lda cos_at_2
		clc
		adc #$03
		sta cos_at_2
		tay

		lda #$00
		sta $d010

		lda sprite_x_cos,x
		clc
		adc sprite_x_cos,y
		bcc spr_x_write

		ldx #$82
		stx $d010

spr_x_write	sta $d00e

		lda #$32
		sta $d00f

		lda #$0f
		sta $03ff

; Play the music
		jsr music+$03

; Set up for second interrupt
		lda #$02
		sta rn
		lda #rstr2p
		sta $d012

		jmp ea31


; Raster split 2
rout2		nop
		nop
		nop

; Raster sync
		ldx #$01
		dex
		bne *-$01
		nop

		lda $d012
		cmp #rstr2p+$01
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea

		lda $d012
		cmp #rstr2p+$02
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea

		lda $d012
		cmp #rstr2p+$03
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea

		lda $d012
		cmp #rstr2p+$04
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea

		lda $d012
		cmp #rstr2p+$05
		bne *+$02
;		sta $d020

		ldx #$06
		dex
		bne *-$01
		nop
		nop
		nop

; Sprite stretcher
		ldx #$00
		ldy #$00

; Change the sprite colour and open the side borders
xflex_stretch	lda colour_data,x
		dec $d016
		sta $d02e
		inc $d016

		bit $ea
		nop

; Actually stretch the sprite
		sty $d017
		sta $d017

		lda #$80
		inx
		cpx #$c6

; Change the X expansion a few times in the middle of the line
		sty $d01d
		sta $d01d
		sty $d01d
		sta $d01d

		bne xflex_stretch

; Wrangle the lower border
		lda #$f9
		cmp $d012
		bne *-$03

		lda #$03
		sta $d011

		lda #$fc
		cmp $d012
		bne *-$03

		lda #$0b
		sta $d011

; Remove the previous frame of stretch data
		ldy stretch_y_offs

!set line_cnt=$00
!do {

!if line_cnt>$00 {
		tya
		clc
		adc stretch_y_offs+line_cnt
		tay
		}

		lda colour_data,y
		ora #$80
		sta colour_data,y

		!set line_cnt=line_cnt+$01
} until line_cnt=$14

; Update the stretcher's offset table
		ldx #$01
stretch_move	lda stretch_y_offs+$01,x
		sta stretch_y_offs+$00,x
		inx
		cpx #$1d
		bne stretch_move

		ldx stretch_cnt
		inx
		cpx #$30
		bcc *+$04
		ldx #$00
		stx stretch_cnt

		lda sprite_y_wibble,x
		sta stretch_y_offs+$1d

; Calculate the height of the stretcher
		ldx #$01
		lda #$00
stretch_calc	clc
		adc stretch_y_offs,x
		inx
		cpx #$1d
		bne stretch_calc

		lsr
		sta stretch_y_offs

		lda #$78
		sec
		sbc stretch_y_offs
		sta stretch_y_offs

; Render the next frame of stretch data
		ldy stretch_y_offs

!set line_cnt=$00
!do {

!if line_cnt>$00 {
		tya
		clc
		adc stretch_y_offs+line_cnt
		tay
		}

		lda colour_data,y
		and #$0f
		sta colour_data,y

		!set line_cnt=line_cnt+$01
} until line_cnt=$14

; Update the ROL scroller
		asl char_buffer+$00
		rol sprite_data+$2f
		rol sprite_data+$2e
		rol sprite_data+$2d

		asl char_buffer+$01
		rol sprite_data+$32
		rol sprite_data+$31
		rol sprite_data+$30

		asl char_buffer+$02
		rol sprite_data+$35
		rol sprite_data+$34
		rol sprite_data+$33

		asl char_buffer+$03
		rol sprite_data+$38
		rol sprite_data+$37
		rol sprite_data+$36

		asl char_buffer+$04
		rol sprite_data+$3b
		rol sprite_data+$3a
		rol sprite_data+$39

; Check to see if the current character is finished
		lda char_buffer+$07
		asl
		sta char_buffer+$07
		cmp #$00
		bne no_def_copy

; Fetch a new character
mread		lda scroll_text
		bne okay
		jsr reset
		jmp mread

okay		sta def_copy+$01
		lda #$00
		asl def_copy+$01
		rol
		asl def_copy+$01
		rol
		asl def_copy+$01
		rol
		clc
		adc #>char_data
		sta def_copy+$02

		lda def_copy+$01
		clc
		adc #<char_data
		bcc *+$05
		inc def_copy+$02
		sta def_copy+$01

; Copy the character definition
		ldx #$00
def_copy	lda char_data,x
		sta char_buffer,x
		inx
		cpx #$08
		bne def_copy

		inc mread+$01
		bne *+$05
		inc mread+$02

no_def_copy

; Set up for first interrupt
		lda #$01
		sta rn
		lda #rstr1p
		sta $d012

; Exit the interrupt
ea31		pla
		tay
		pla
		tax
		pla
nmi		rti

; Reset code for the scroller's self mod
reset		lda #<scroll_text
		sta mread+$01
		lda #>scroll_text
		sta mread+$02

		rts


; Sprite colours
sprite_cols	!byte $00,$00,$00

		!byte $0d,$0d,$0d,$03,$0d,$03,$03,$03
		!byte $05,$03,$05,$05,$05,$04,$05

		!byte $04,$04,$04,$0e,$04,$0e,$0e,$0e
		!byte $03,$0e,$03,$03,$03,$0d,$03,$0d
		!byte $0d,$0d,$01,$0d,$01,$01,$01,$0d
		!byte $01,$0d,$0d,$0d,$03,$0d,$03,$03
		!byte $03,$05,$03,$05,$05,$05,$04,$05

		!byte $04,$04,$04,$05,$04,$05,$05,$05
		!byte $03,$05,$03,$03,$03,$0d,$03,$0d
		!byte $0d,$0d,$01,$0d,$01,$01,$01,$07
		!byte $01,$07,$07,$07,$03,$07,$03,$03
		!byte $03,$0e,$03,$0e,$0e,$0e,$08,$0e

		!byte $08,$08,$08,$05,$08,$05,$05,$05
		!byte $03,$05,$03,$03,$03,$07,$03,$07
		!byte $07,$07,$01,$07,$01,$01,$01,$07
		!byte $01,$07,$07,$07,$0f,$07,$0f,$0f
		!byte $0f,$05,$0f,$05,$05,$05,$08,$05

		!byte $08,$08,$08,$0a,$08,$0a,$0a,$0a
		!byte $0f,$0a,$0f,$0f,$0f,$07,$0f,$07
		!byte $07,$07,$01,$07,$01,$01,$01,$07
		!byte $01,$07,$07,$07,$0f,$07,$0f,$0f
		!byte $0f,$0a,$0f,$0a,$0a,$0a,$08,$0a

		!byte $08,$08,$08,$0e,$08,$0e,$0e,$0e
		!byte $0f,$0e,$0f,$0f,$0f,$0d,$0f,$0d
		!byte $0d,$0d

; Sprite X cosine
sprite_x_cos	!byte $a1,$a1,$a1,$a1,$a1,$a1,$a1,$a0
		!byte $a0,$a0,$9f,$9f,$9e,$9d,$9d,$9c
		!byte $9b,$9b,$9a,$99,$98,$97,$96,$95
		!byte $94,$93,$92,$90,$8f,$8e,$8c,$8b
		!byte $8a,$88,$87,$85,$84,$82,$81,$7f
		!byte $7d,$7c,$7a,$78,$77,$75,$73,$71
		!byte $6f,$6e,$6c,$6a,$68,$66,$64,$62
		!byte $60,$5e,$5c,$5a,$58,$56,$54,$52

		!byte $50,$4e,$4c,$4a,$48,$46,$44,$42
		!byte $41,$3f,$3d,$3b,$39,$37,$35,$33
		!byte $31,$30,$2e,$2c,$2a,$28,$27,$25
		!byte $23,$22,$20,$1f,$1d,$1b,$1a,$18
		!byte $17,$16,$14,$13,$12,$11,$0f,$0e
		!byte $0d,$0c,$0b,$0a,$09,$08,$07,$06
		!byte $06,$05,$04,$04,$03,$02,$02,$01
		!byte $01,$01,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$01
		!byte $01,$02,$02,$03,$03,$04,$04,$05
		!byte $06,$07,$07,$08,$09,$0a,$0b,$0c
		!byte $0d,$0e,$10,$11,$12,$13,$15,$16
		!byte $17,$19,$1a,$1c,$1d,$1f,$21,$22
		!byte $24,$25,$27,$29,$2b,$2c,$2e,$30
		!byte $32,$34,$36,$37,$39,$3b,$3d,$3f
		!byte $41,$43,$45,$47,$49,$4b,$4d,$4f

		!byte $51,$53,$55,$57,$59,$5b,$5d,$5f
		!byte $61,$63,$65,$67,$68,$6a,$6c,$6e
		!byte $70,$72,$74,$75,$77,$79,$7b,$7c
		!byte $7e,$80,$81,$83,$84,$86,$87,$89
		!byte $8a,$8c,$8d,$8e,$8f,$91,$92,$93
		!byte $94,$95,$96,$97,$98,$99,$9a,$9b
		!byte $9c,$9c,$9d,$9e,$9e,$9f,$9f,$a0
		!byte $a0,$a0,$a1,$a1,$a1,$a1,$a1,$a1

; Sprite stretcher movement data
sprite_y_wibble	!byte $01,$01,$02,$02,$03,$03,$04,$04
		!byte $05,$05,$06,$06,$07,$07,$08,$08
		!byte $09,$09,$0a,$0a,$0b,$0b,$0c,$0c
		!byte $0b,$0b,$0a,$0a,$09,$09,$08,$08
		!byte $07,$07,$06,$06,$05,$05,$04,$04
		!byte $03,$03,$02,$02,$01,$01,$01,$01

; Stretcher offset table (first byte is overall height)
stretch_y_offs	!byte $00
		!byte $0a,$0a,$0b,$0b,$0c,$0c,$0b,$0b
		!byte $0a,$0a,$09,$09,$08,$08,$07,$07
		!byte $06,$06,$05,$05,$04,$04,$03,$03
		!byte $02,$02,$01,$01,$01,$01


; Character set
char_data	!binary "data/4x5_chars.bin"

; Got to have a scroller... s'in the rules!
scroll_text	!scr "-+- one sprite wander -+-"
		!scr "     "

		!scr "code, graphics, music and poor design "
		!scr "choices by t.m.r"
		!scr "     "

		!scr "just using one sprite with the side "
		!scr "borders open and several register "
		!scr "changes per line for the x wibble..."
		!scr "     "

		!scr "i suspect that nobody will actually "
		!scr "be reading this, so i might as well "
		!scr "just greet all of cosine's friends, "
		!scr "plug cosine.org.uk and then wander "
		!scr "off!"
		!scr "     "

		!scr "t.m.r of cosine on 2019-12-13"
		!scr "      "

		!byte $00
