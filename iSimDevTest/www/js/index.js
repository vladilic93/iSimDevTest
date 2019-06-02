let takePhotoButton = document.getElementById("btn-take-photo");    
window.onload = function() {
  takePhotoButton.addEventListener('click', function() {
    window.webkit.messageHandlers.Image.postMessage("TakeNew");
  }, false);

  let errorCloseButton = document.getElementById('btn-close-error');
  errorCloseButton.addEventListener('click', function() {
    let alertContainer = document.getElementById('alert');
    alertContainer.style.display = 'none';
  }, false);
}

function showError(message) {
  let errorContainer = document.getElementById('alert');
  errorContainer.style.display = 'block';

  let errorContentContainer = document.getElementById('error-content');
  errorContentContainer.innerText = message;
}

function setImage(b64ImageData) {
  let image_src = 'data:image/png;base64,' + b64ImageData;
  let img = document.getElementById('image-displayed');
  if (img) {
    img.setAttribute('src', image_src);
  } else {
    let img = document.createElement("img");
    img.setAttribute('src', image_src); 
    img.setAttribute('alt', 'Display of image taken.');
    img.id = "image-displayed";
    
    let container = document.getElementById("image-container");
    container.appendChild(img);
  }
}

function toggleBusy(on) {
  let overlay = document.getElementById('overlay');
  let display = overlay.style.display;
  
  overlay.style.display = on ? 'block' : 'none';
}
