{

  Dynamic array support for
  TCustomGrid, TDrawGrid and TStringGrid for Lazarus
  Copyright (C) 2002  Jesus Reyes Aguilar.
  email: jesusrmx@yahoo.com.mx


THIS CONTROL IS FREEWARE - USE AS YOU WILL
If you release sourcecode that uses this control, please credit me
or leave this header intact.  If you release a compiled application
that uses this code, please credit me somewhere in a little bitty
location so I can at least get bragging rights!

This code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.



RELEASE DATE: 30-NOV-2002
VERSION: 0.9.0

}

unit DynamicArray;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

Type
  EArray=Class(Exception);
  
  TOnNotifyItem = Procedure(Sender: TObject; Col,Row: integer; Var Item: Pointer) of Object;
  TOnCompareItem = Function (Sender: TObject; Acol,ARow,Bcol,BRow: Integer): Integer of Object;
  TOnExchangeItem = Procedure (Sender: TObject; Index, WithIndex: Integer) of Object;

  TArray=Class
  Private
    FCols: TList;
    Fondestroyitem: TOnNotifyItem;
    FOnNewItem: TonNotifyItem;
    Function Getarr(Col, Row: Integer): Pointer;
    Procedure Setarr(Col, Row: Integer; Const Avalue: Pointer);
    Procedure ClearCol(L: TList; Col: Integer);
    Procedure Aumentar_Rows(col,Rows: Integer; L: TList);
    Procedure DestroyItem(Col,Row: Integer; P: Pointer);
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure SetLength(Cols,Rows: Integer);

    Procedure DeleteColRow(IsColumn: Boolean; Index: Integer);
    Procedure MoveColRow(IsColumn:Boolean; FromIndex, ToIndex: Integer);
    Procedure ExchangeColRow(IsColumn:Boolean; Index, WithIndex: Integer);
    Procedure Clear;
    
    Property Arr[Col,Row: Integer]: Pointer Read GetArr Write SetArr; Default;
    Property OnDestroyItem: TOnNotifyItem Read FOnDestroyItem Write FOnDestroyItem;
    Property OnNewItem: TOnNotifyItem Read FOnNewItem Write FOnNewItem;
  End;

implementation

{ TArray }

Function Tarray.Getarr(Col, Row: Integer): Pointer;
Begin
  // Checar dimensiones
  Result:= TList(FCols[Col])[Row];
End;

Procedure Tarray.Setarr(Col, Row: Integer; Const Avalue: Pointer);
Begin
  // Checar dimensiones
  TList(FCols[Col])[Row]:=aValue;
End;

Procedure TArray.ClearCol(L: TList; Col: Integer);
Var
   j: Integer;
Begin
  If L<>Nil Then begin
    For j:=0 to L.Count-1 do DestroyItem(Col,J, L[J]);
    L.Clear;
  End;
End;

Procedure Tarray.Clear;
Var
   i: Integer;
Begin
  {$Ifdef dbgMem}WriteLn('TArray.Clear');{$endif}
  For i:=0 to FCols.Count-1 do begin
    ClearCol(TList(FCols[i]), i);
    TList(FCols[i]).Free;
  End;
  FCols.Clear;
End;

Constructor Tarray.Create;
Begin
  Inherited Create;
  FCols:=TList.Create;
End;

Destructor Tarray.Destroy;
Begin
  {$Ifdef dbgMem}WriteLn('TArray.Destroy FCols.Count=',FCols.Count);{$endif}
  Clear;
  FCols.free;
  Inherited Destroy;
End;

Procedure TArray.Aumentar_Rows(col,rows: Integer; L: TList);
var
   i,j: Integer;
   P:Pointer;
begin
  //WriteLn('TArray.Aumentar_Rows: Col=',Col,' Rows=',Rows);
  i:=L.Count;
  j:=Rows-L.Count;
  While j>0 do begin
    P:=nil;
    if Assigned(OnNewItem) Then OnNewItem(Self, col, i, P);
    L.Add(P);
    dec(j);
    inc(i);
  End;
End;

procedure TArray.DestroyItem(Col, Row: Integer; P: Pointer);
begin
  If (P<>nil)And Assigned(OnDestroyItem) Then OnDestroyItem(Self, Col, Row, P);
end;

Procedure Tarray.Setlength(Cols, Rows: Integer);
Var
   i,j: integer;
   L: TList;
   //P: Pointer;
Begin
  {$IfDef DbgMem}WriteLn('TArray.SetLength: Cols=',Cols,' Rows=',Rows);{$Endif}
  //
  // Ajustar columnas
  //
  If FCols.Count>Cols Then begin
    // Hay mas columnas de las que debe.
    // Destruir las columnas innecesarias
    for i:=Cols to fCols.Count-1 do begin
      L:=TList(FCols[i]);
      ClearCol(L, i);
      L.Free;
      L:=nil;
    End;
  End;
  FCols.Count:=Cols;
     
  //
  // Ajustar Renglones
  //
  For i:=0 to fCols.Count-1 do begin
    L:=TList(FCols[i]);
    If L=nil Then L:=TList.Create;
    If L.Count>Rows Then begin
      For j:=Rows to L.Count-1 do DestroyItem(i,j,L[j]);
      L.Count:=Rows;
    End;
    Aumentar_Rows(i, Rows, L);
    FCols[i]:=L;
  End;
End;

procedure TArray.DeleteColRow(IsColumn: Boolean; Index: Integer);
Var
  i: Integer;
  L: TList;
begin
  If IsColumn Then begin
    {$Ifdef dbgMem}WriteLn('TArray.DeleteColRow Col=',Index);{$endif}
    L:=TList(FCols[Index]);
    If L<>nil then begin
      ClearCol(L, Index);
      FCols.Delete(Index);
      L.Free;
    End;
  End Else begin
    {$Ifdef dbgMem}WriteLn('TArray.DeleteColRow Row=',Index);{$endif}
    For i:=0 to fCols.Count-1 do begin
      L:=TList(fcols[i]);
      If L<>nil then Begin
        DestroyItem(i, Index, L[Index]);
        L.Delete(Index);
      End;
    End;
  End;
end;

procedure TArray.MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer);
Var
  i: Integer;
begin
  If IsColumn Then begin
    FCols.Move(FromIndex, ToIndex);
  End Else begin
    For i:=0 to FCols.Count-1 do
      TList(Fcols[i]).Move(FromIndex,ToIndex);
  End;
end;

procedure TArray.ExchangeColRow(IsColumn: Boolean; Index, WithIndex: Integer);
Var
  i: Integer;
begin
  If IsColumn Then begin
    FCols.Exchange(Index, WithIndex);
  End Else begin
    For i:=0 to FCols.Count-1 do
      TList(FCols[i]).Exchange(Index, WithIndex);
  End;
end;
end.

