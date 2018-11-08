unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Net.Socket, System.Threading;

type
  TTCPDaemon = class(TThread)
  private
    FSock: TSocket;
  public
    constructor Create;
    Destructor Destroy; override;
    procedure Execute; override;
  end;

  TTCPThrd = class(TThread)
  private
    FSock: TSocket;
    constructor Create(ASock:TSocket);
    procedure Execute; override;
    procedure SendCallBack(const ar: IAsyncResult);
  end;

  TForm1 = class(TForm)
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormDestroy(Sender: TObject);
  private
    TCPHttpDaemon: TTCPDaemon;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


procedure TForm1.FormDestroy(Sender: TObject);
begin
  TCPHttpDaemon.Terminate;
  TCPHttpDaemon.WaitFor;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  TCPHttpDaemon := TTCPDaemon.Create;
end;

{ TTCPHttpDaemon }

constructor TTCPDaemon.Create;
begin
  inherited create(false);
  FSock:=TSocket.create(TSocketType.TCP, TEncoding.UTF8);
  FreeOnTerminate:=true;
end;

Destructor TTCPDaemon.Destroy;
begin
  FSock.Free;
  inherited Destroy;
end;

procedure TTCPDaemon.Execute;

  function _Accept(Timeout: Cardinal): TSocket;
  var
    ReadFds: TFDSet;
  begin
    ReadFds := TFDSet.Create(FSock);
    if TSocket.Select(ReadFds, nil, nil, Timeout) = wrSignaled then
      Result := FSock.Accept
    else
      Result := nil;
  end;

var
  ClientSock: TSocket;
begin
  FSock.Listen(TNetEndpoint.Create(TIPAddress.LocalHost, 8088));
  repeat
    if Terminated then Break;
    ClientSock:=_Accept(1000);
    if Assigned(ClientSock) then
        TTCPThrd.Create(ClientSock);
  until False;
  FSock.Close(True);
end;

{ TTCPHttpThrd }

constructor TTCPThrd.Create(ASock: TSocket);
begin
  FSock:=ASock;
  FreeOnTerminate:=true;
  inherited create(false);
end;

procedure TTCPThrd.Execute;
var
  LResponse: TBytes;
begin
  FSock.Receive(LResponse);
  FSock.BeginSend('PUK', SendCallBack).AsyncWaitEvent.WaitFor();
end;

procedure TTCPThrd.SendCallBack(const ar: IAsyncResult);
var
  LHandle: TSocket;
begin
  LHandle := TSocket(ar.AsyncContext);
  try
    LHandle.EndSend(ar);
  finally
    LHandle.Close(True);
    LHandle.Free;
  end;
end;

end.
