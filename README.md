# autoshutdown script for Qubes OS

## Important warnings
**Disclaimer:** This script is not maintained by the Qubes OS team.

**Warning:** This script is rather experimental. You might find it useful, but it might also cease to work, shut down a VM you are using and so on.

## Installation

You need xdotool installed in dom0.

You can install it by adding a line like the following one to crontab:

    @reboot ~/auto-shutdown/loop.sh

## Modularity

The script is modular: You can add a new strategy for determining if a VM is *active*. If a VM is *active*, it is doing something potentially useful. If VM is not active, it might be running, but without being useful. There are currently two strategies:

* Blacklist: always marks `dom0`, `sys-net` and `sys-firewall` as *active*.
* X11: marks all VMs with a visible window (it seemingly includes systray icons) as *active*.

## Known issues

### Potential race condition

When VM is about being shut down and user starts an app, it might not notice the user's action in time. This might be improved by tight cooperation with Dom0<->DomU communication libraries.

With a following assumption and a tight cooperation, we could even fully fix the race condition: When a VM is not *active*, it will not begin *active* unless user does some action through qragent.

* This assumption seems to be reasonable. User can't directly interact with machines without a visible X11 window. He might interact through qragent or (in some special cases) through other interfaces like network and peripherial devices.
	* When user interacts through network or some periprerial device, he should blacklist the VM from automatic shutdown.
	* When the user interacts through qragent, we can catch it by some tight integration
* If qragent would provide shutdownPrepare and shutdownProceed function, we could fully fix the race condition.
	* The shutdownPrepare function would change the qragent state to *preparing-for-shutdown* and return a new ShutdownTicket. The VM is in *preparing-for-shutdown* state iff there is a valid ShutdownTicket.
	* Any qrexec API call (except some special cases) would invalidate the ShutdownTicket. (It would invalidate all ShutdownTicket-s if we allow more valid ShutdownTicket-s at one time instant.)
	* After shutdownPrepare call, the script can check if a VM is active. If so, the ShutdownTicket can be cancelled.
	* When all *activity*-related checks are passed and the VM is found to be *inactive*, the shutdownProceed function with the corresponding ShutdownTicket is called.
	* The shutdownProceed function shuts the machine down iff the ShutdownTicket is valid.
	* Some serialization in qragent is assumed. I am not sure about the qragent design, but I hope this assumption is reasonable.

### It does not react to free RAM

It does the shutdown even if there is much free RAM. It could be optimized to shut the VM down iff there is low memory. This would however need either a frequent polling (=> higher CPU and power consumption) or tight cooperation with the Qubes memory manager.

### Service VMs

If you are using a service VM, it should be blacklisted. See `activity.d/00_blacklist`. The sys-firewall, sys-net and dom0 VMs are balcklisted by default. If you create a TorVM, USBVM, StorageVM or a ServerVM, you might want to add it to the blacklist.

### Some edge cases

Yes, some parts of the script are hacky, especially the function qvm-ls-running. These parts might fail in some special conditions.

## License

WTFPL, without any warranty.
